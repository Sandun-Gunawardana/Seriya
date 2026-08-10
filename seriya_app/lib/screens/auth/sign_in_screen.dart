import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_page_shell.dart';
import 'phone_verification_screen.dart';
import 'registration_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isBusy = true);
    try {
      final phone = normalizeSriLankanPhoneNumber(_phoneController.text);
      final session = await widget.authService.sendPhoneCode(phone);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PhoneVerificationScreen.signIn(
            authService: widget.authService,
            phoneNumber: phone,
            session: session,
          ),
        ),
      );
    } on AuthFlowException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(
                color: seriyaNavy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Sign in with your registered mobile number.',
              style: TextStyle(
                color: seriyaNavy.withValues(alpha: 0.58),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 23),
            TextFormField(
              key: const Key('signInPhone'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                LengthLimitingTextInputFormatter(16),
              ],
              onFieldSubmitted: (_) => _sendCode(),
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '076 123 4567',
                helperText: 'Sri Lankan numbers only (+94)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: validateSriLankanPhoneNumber,
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: _isBusy ? 'Sending code…' : 'Send verification code',
              icon: _isBusy
                  ? Icons.hourglass_top_rounded
                  : Icons.sms_outlined,
              onPressed: _isBusy ? () {} : _sendCode,
            ),
            const SizedBox(height: 19),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New to Seriya?',
                  style: TextStyle(color: seriyaNavy.withValues(alpha: 0.62)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            RegistrationScreen(authService: widget.authService),
                      ),
                    );
                  },
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: seriyaSoftTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: seriyaTeal, size: 19),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Vehicle and route access becomes available after administrator approval and assignment.',
                      style: TextStyle(
                        color: seriyaNavy,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
