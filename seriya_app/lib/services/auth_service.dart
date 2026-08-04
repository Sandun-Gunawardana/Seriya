import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Development-only switch. Set this to true before production release.
const bool requireEmailVerification = false;

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
    required this.password,
    required this.requestedRole,
  });

  final String fullName;
  final String employeeId;
  final String email;
  final String phone;
  final String password;
  final String requestedRole;
}

abstract class AuthService {
  Future<SignInResult> signIn({
    required String email,
    required String password,
  });

  Future<void> register(RegistrationDetails details);

  Future<void> sendPasswordResetEmail(String email);
}

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthFlowException('Unable to sign in. Please try again.');
      }
      if (requireEmailVerification && !user.emailVerified) {
        await _auth.signOut();
        throw const AuthFlowException(
          'Verify your email address before signing in.',
        );
      }

      final profile = await _firestore.collection('users').doc(user.uid).get();
      if (!profile.exists) {
        await _auth.signOut();
        throw const AuthFlowException(
          'Your employee profile was not found. Contact the administrator.',
        );
      }

      final data = profile.data() ?? <String, dynamic>{};
      final status = _parseStatus(data['status'] as String?);
      final role =
          (data['approvedRole'] as String?) ??
          (data['requestedRole'] as String?) ??
          'passenger';

      if (status != AccountStatus.approved) {
        await _auth.signOut();
      }
      return SignInResult(status: status, role: role);
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_messageForAuthCode(error.code));
    } on FirebaseException catch (error) {
      throw AuthFlowException(_messageForFirebaseError(error));
    }
  }

  @override
  Future<void> register(RegistrationDetails details) async {
    User? createdUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: details.email.trim(),
        password: details.password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        throw const AuthFlowException(
          'The account could not be created. Please try again.',
        );
      }

      await createdUser.updateDisplayName(details.fullName.trim());
      await _firestore.collection('users').doc(createdUser.uid).set({
        'fullName': details.fullName.trim(),
        'employeeId': details.employeeId.trim().toUpperCase(),
        'email': createdUser.email ?? details.email.trim(),
        'phone': details.phone.trim(),
        'requestedRole': details.requestedRole,
        'approvedRole': null,
        'status': 'pending',
        'routeId': null,
        'vehicleId': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (requireEmailVerification) {
        await createdUser.sendEmailVerification();
      }
      await _auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_messageForAuthCode(error.code));
    } on FirebaseException catch (error) {
      await _deleteIncompleteUser(createdUser);
      throw AuthFlowException(_messageForFirebaseError(error));
    } on AuthFlowException {
      rethrow;
    } catch (_) {
      await _deleteIncompleteUser(createdUser);
      throw const AuthFlowException(
        'Registration could not be completed. Please try again.',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFlowException(_messageForAuthCode(error.code));
    }
  }

  Future<void> _deleteIncompleteUser(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
    } catch (_) {
      // An administrator can remove the rare orphaned account if cleanup fails.
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
      'email-already-in-use' =>
        'An account already exists for this email address.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' =>
        'Choose a stronger password with at least 8 characters.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'The email address or password is incorrect.',
      'user-disabled' =>
        'This account has been disabled. Contact the administrator.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' =>
        'Network connection failed. Check your internet and try again.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  String _messageForFirebaseError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Database access is not configured. Contact the administrator.';
    }
    if (error.code == 'unavailable') {
      return 'The service is temporarily unavailable. Please try again.';
    }
    return 'Firebase could not complete the request. Please try again.';
  }
}
