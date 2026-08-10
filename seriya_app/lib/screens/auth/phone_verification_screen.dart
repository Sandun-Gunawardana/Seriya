import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/requested_role.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_page_shell.dart';
import '../dashboard_screen.dart';
import 'registration_success_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen.signIn({
    super.key,
    required this.authService,
    required this.phoneNumber,
    required this.session,
  }) : registrationDetails = null;

  const PhoneVerificationScreen.registration({
    super.key,
    required this.authService,
    required this.phoneNumber,
    required this.session,
    required RegistrationDetails details,
  }) : registrationDetails = details;

  final AuthService authService;
  final String phoneNumber;
  final PhoneCodeSession session;
  final RegistrationDetails? registrationDetails;

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late PhoneCodeSession _session;
  bool _isBusy = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    FocusScope.of(context).unfocus();
    if (_session.codeRequired &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      final details = widget.registrationDetails;
      if (details != null) {
        await widget.authService.registerWithPhoneCode(
          session: _session,
          smsCode: _codeController.text,
          details: details,
        );
        if (!mounted) return;
        final role = details.requestedRole == 'driver'
            ? RequestedRole.driver
            : RequestedRole.passenger;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RegistrationSuccessScreen(role: role),
          ),
        );
        return;
      }

      final result = await widget.authService.verifySignInCode(
        session: _session,
        smsCode: _codeController.text,
      );
      if (!mounted) return;
      _openForStatus(result);
    } on AuthFlowException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _openForStatus(SignInResult result) {
    switch (result.status) {
      case AccountStatus.approved:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
          (_) => false,
        );
      case AccountStatus.pending:
        final role = result.role == 'driver'
            ? RequestedRole.driver
            : RequestedRole.passenger;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => RegistrationSuccessScreen(role: role),
          ),
        );
      case AccountStatus.rejected:
        _showError(
          'Your registration was not approved. Contact the administrator.',
        );
      case AccountStatus.disabled:
        _showError('Your account is disabled. Contact the administrator.');
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      final session = await widget.authService.sendPhoneCode(
        widget.phoneNumber,
      );
      if (!mounted) return;
      setState(() {
        _session = session;
        _codeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification code was sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthFlowException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify your phone',
              style: TextStyle(
                color: seriyaNavy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}.',
              style: TextStyle(
                color: seriyaNavy.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('verificationCode'),
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onFieldSubmitted: (_) => _verifyCode(),
              decoration: const InputDecoration(
                labelText: 'Verification code',
                hintText: '123456',
                prefixIcon: Icon(Icons.password_rounded),
              ),
              validator: (value) => value == null || value.length != 6
                  ? 'Enter the 6-digit verification code'
                  : null,
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: _isBusy ? 'Verifying…' : 'Verify and continue',
              icon: _isBusy
                  ? Icons.hourglass_top_rounded
                  : Icons.verified_user_outlined,
              onPressed: _isBusy ? () {} : _verifyCode,
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _isBusy || _isResending ? null : _resendCode,
                child: Text(
                  _isResending ? 'Sending…' : 'Did not receive it? Resend',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
