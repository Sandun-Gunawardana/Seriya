import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/requested_role.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_page_shell.dart';
import 'phone_verification_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  RequestedRole _role = RequestedRole.passenger;
  bool _acceptedTerms = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please accept the Terms and Privacy Policy'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    if (!isValid || !_acceptedTerms) return;

    setState(() => _isBusy = true);
    try {
      final details = RegistrationDetails(
        fullName: _fullNameController.text,
        employeeId: _employeeIdController.text,
        email: _emailController.text,
        phone: normalizeSriLankanPhoneNumber(_phoneController.text),
        requestedRole: _role.name,
      );
      final session = await widget.authService.sendPhoneCode(details.phone);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PhoneVerificationScreen.registration(
            authService: widget.authService,
            phoneNumber: details.phone,
            session: session,
            details: details,
          ),
        ),
      );
    } on AuthFlowException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
              'Create your account',
              style: TextStyle(
                color: seriyaNavy,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Verify your mobile number, then an administrator will review your account and make the vehicle assignment.',
              style: TextStyle(
                color: seriyaNavy.withValues(alpha: 0.58),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('I am registering as'),
            const SizedBox(height: 9),
            Row(
              children: [
                for (final role in RequestedRole.values) ...[
                  Expanded(
                    child: _RoleCard(
                      role: role,
                      selected: role == _role,
                      onTap: () => setState(() => _role = role),
                    ),
                  ),
                  if (role != RequestedRole.values.last)
                    const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('fullName'),
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('employeeId'),
              controller: _employeeIdController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your employee ID'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('registrationEmail'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address (optional)',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return validateEmail(value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('phoneNumber'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: const InputDecoration(
                labelText: 'Mobile number (required)',
                hintText: '076 123 4567',
                helperText: 'This will be your sign-in number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              validator: validateSriLankanPhoneNumber,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 38,
                      child: Checkbox(
                        value: _acceptedTerms,
                        activeColor: seriyaTeal,
                        onChanged: (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                      ),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 11),
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              color: seriyaNavy,
                              fontSize: 12,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: seriyaTeal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: seriyaTeal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            AuthPrimaryButton(
              label: _isBusy ? 'Sending code…' : 'Verify phone and register',
              icon: _isBusy
                  ? Icons.hourglass_top_rounded
                  : Icons.how_to_reg_rounded,
              onPressed: _isBusy ? () {} : _register,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: seriyaNavy,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final RequestedRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? seriyaSoftTeal : const Color(0xFFF5F8F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: selected ? seriyaTeal : const Color(0xFFDDE6E3),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(role.icon, color: selected ? seriyaTeal : seriyaNavy),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: seriyaTeal,
                      size: 19,
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                role.title,
                style: const TextStyle(
                  color: seriyaNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                role.description,
                maxLines: 3,
                style: TextStyle(
                  color: seriyaNavy.withValues(alpha: 0.55),
                  fontSize: 9,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
