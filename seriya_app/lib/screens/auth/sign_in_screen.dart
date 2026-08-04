import 'package:flutter/material.dart';

import '../../widgets/auth_page_shell.dart';
import '../dashboard_screen.dart';
import 'registration_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _hidePassword = true;
  bool _rememberMe = true;

  void _signIn() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DashboardScreen()),
    );
  }

  void _showPasswordReset() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: const Text(
          'Password recovery will send a secure reset link to your registered email address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
                  onPressed: _showPasswordReset,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AuthPrimaryButton(
              label: 'Sign in',
              icon: Icons.arrow_forward_rounded,
              onPressed: _signIn,
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
                        builder: (_) => const RegistrationScreen(),
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
