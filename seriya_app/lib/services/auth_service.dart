import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

enum AccountStatus { pending, approved, rejected, disabled }

class SignInResult {
  const SignInResult({required this.status, required this.role});

  final AccountStatus status;
  final String role;
}

class RegistrationDetails {
  const RegistrationDetails({
    required this.fullName,
    required this.employeeId,
    required this.email,
    required this.phone,
    required this.requestedRole,
  });

  final String fullName;
  final String employeeId;
  final String email;
  final String phone;
  final String requestedRole;
}

class PhoneCodeSession {
  const PhoneCodeSession._({required this.challengeId});

  const PhoneCodeSession.test() : challengeId = 'test-challenge';

  final String challengeId;
  bool get codeRequired => true;
}

abstract class AuthService {
  Future<PhoneCodeSession> sendPhoneCode(String phoneNumber);

  Future<SignInResult> verifySignInCode({
    required PhoneCodeSession session,
    required String smsCode,
  });

  Future<void> registerWithPhoneCode({
    required PhoneCodeSession session,
    required String smsCode,
    required RegistrationDetails details,
  });
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

String normalizeSriLankanPhoneNumber(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('94')) {
    return '+$digits';
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return '+94$digits';
}

String? validateSriLankanPhoneNumber(String? value) {
  final normalized = normalizeSriLankanPhoneNumber(value ?? '');
  return RegExp(r'^\+947\d{8}$').hasMatch(normalized)
      ? null
      : 'Enter a valid Sri Lankan mobile number';
}

/// Uses the Seriya Vercel backend for Text.lk OTP verification, then signs in
/// to Firebase with the custom token returned by that trusted backend.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    http.Client? client,
    String? apiBaseUrl,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _client = client ?? http.Client(),
       _apiBaseUrl = _normalizeBaseUrl(
         apiBaseUrl ??
             const String.fromEnvironment(
               'AUTH_API_BASE_URL',
               defaultValue: 'https://seriya-backend.vercel.app',
             ),
       );

  final FirebaseAuth _auth;
  final http.Client _client;
  final String _apiBaseUrl;

  @override
  Future<PhoneCodeSession> sendPhoneCode(String phoneNumber) async {
    final response = await _post('/api/auth/send-otp', {
      'phone': normalizeSriLankanPhoneNumber(phoneNumber),
    });
    final challengeId = response['challengeId'];
    if (challengeId is! String || challengeId.isEmpty) {
      throw const AuthFlowException(
        'The verification service returned an invalid response.',
      );
    }
    return PhoneCodeSession._(challengeId: challengeId);
  }

  @override
  Future<SignInResult> verifySignInCode({
    required PhoneCodeSession session,
    required String smsCode,
  }) async {
    final response = await _post('/api/auth/verify-otp', {
      'challengeId': session.challengeId,
      'code': smsCode.trim(),
      'mode': 'signIn',
    });
    await _signInWithBackendToken(response);

    final status = _parseStatus(response['status'] as String?);
    final role = response['approvedRole'] is String
        ? response['approvedRole']! as String
        : 'passenger';
    if (status != AccountStatus.approved) {
      await _auth.signOut();
    }
    return SignInResult(status: status, role: role);
  }

  @override
  Future<void> registerWithPhoneCode({
    required PhoneCodeSession session,
    required String smsCode,
    required RegistrationDetails details,
  }) async {
    final response = await _post('/api/auth/verify-otp', {
      'challengeId': session.challengeId,
      'code': smsCode.trim(),
      'mode': 'registration',
      'profile': {
        'fullName': details.fullName.trim(),
        'employeeId': details.employeeId.trim().toUpperCase(),
        'email': details.email.trim().toLowerCase(),
        'requestedRole': details.requestedRole,
      },
    });
    await _signInWithBackendToken(response);
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_apiBaseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw const AuthFlowException(
        'Could not reach the verification service. Check your internet and try again.',
      );
    }

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(response.body);
      payload = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      payload = <String, dynamic>{};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'];
      final message = error is Map<String, dynamic> ? error['message'] : null;
      throw AuthFlowException(
        message is String && message.isNotEmpty
            ? message
            : 'The verification request failed. Please try again.',
      );
    }
    return payload;
  }

  Future<void> _signInWithBackendToken(Map<String, dynamic> response) async {
    final token = response['customToken'];
    if (token is! String || token.isEmpty) {
      throw const AuthFlowException(
        'The verification service did not return a Firebase session.',
      );
    }
    try {
      await _auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_messageForAuthCode(error.code));
    }
  }

  AccountStatus _parseStatus(String? value) {
    return switch (value) {
      'approved' => AccountStatus.approved,
      'rejected' => AccountStatus.rejected,
      'disabled' => AccountStatus.disabled,
      _ => AccountStatus.pending,
    };
  }

  String _messageForAuthCode(String code) {
    return switch (code) {
      'invalid-custom-token' || 'custom-token-mismatch' =>
        'The Firebase login configuration is invalid. Contact the administrator.',
      'network-request-failed' =>
        'Network connection failed. Check your internet and try again.',
      'user-disabled' => 'Your account is disabled. Contact the administrator.',
      _ => 'Firebase could not start your session. Please try again.',
    };
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
