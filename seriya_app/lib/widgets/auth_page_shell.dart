import 'package:flutter/material.dart';

const seriyaNavy = Color(0xFF10243E);
const seriyaTeal = Color(0xFF0F9D8B);
const seriyaSoftTeal = Color(0xFFE4F6F2);

class AuthPageShell extends StatelessWidget {
  const AuthPageShell({
    super.key,
    required this.child,
    this.showBackButton = false,
  });

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE5F6F2), Color(0xFFF7FAF9), Color(0xFFEEF4F2)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                    maxWidth: 520,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBackButton)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton.filledTonal(
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Back',
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      if (!showBackButton) const SizedBox(height: 12),
                      const _SeriyaBrand(),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F10243E),
                              blurRadius: 32,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SeriyaBrand extends StatelessWidget {
  const _SeriyaBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: seriyaTeal,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D0F9D8B),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: Colors.white,
            size: 39,
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'SERIYA',
          style: TextStyle(
            color: seriyaNavy,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your daily ride, right on time',
          style: TextStyle(
            color: seriyaNavy.withValues(alpha: 0.58),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: seriyaTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
        label: Text(label),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address';
  }
  return null;
}
