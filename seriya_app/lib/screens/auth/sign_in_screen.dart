import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/auth_page_shell.dart';
import '../dashboard_screen.dart';
import 'registration_screen.dart';
import 'registration_success_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  bool _rememberMe = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isBusy = true);
    try {
      final result = await widget.authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;

      switch (result.status) {
        case AccountStatus.approved:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
          );
        case AccountStatus.pending:
          final role = result.role == 'driver'
              ? RequestedRole.driver
              : RequestedRole.passenger;
          Navigator.of(context).push(
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
    } on AuthFlowException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showPasswordReset() async {
    final validationMessage = validateEmail(_emailController.text);
    if (validationMessage != null) {
      _showError('Enter your registered email address first.');
      return;
    }

    setState(() => _isBusy = true);
    try {
      await widget.authService.sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check your email'),
          content: const Text(
            'A secure password-reset link has been sent to your email address.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
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
              'Sign in to view your assigned trip and live vehicle.',
              style: TextStyle(
                color: seriyaNavy.withValues(alpha: 0.58),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 23),
            TextFormField(
              key: const Key('signInEmail'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 15),
            TextFormField(
              key: const Key('signInPassword'),
              controller: _passwordController,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _signIn(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                if (value.length < 6) {
                  return 'Password must have at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: seriyaTeal,
                    onChanged: (value) =>
                        setState(() => _rememberMe = value ?? false),
                  ),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    color: seriyaNavy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isBusy ? null : _showPasswordReset,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AuthPrimaryButton(
              label: _isBusy ? 'Signing in…' : 'Sign in',
              icon: _isBusy
                  ? Icons.hourglass_top_rounded
                  : Icons.arrow_forward_rounded,
              onPressed: _isBusy ? () {} : _signIn,
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
