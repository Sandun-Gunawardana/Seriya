import 'package:flutter/material.dart';

import '../../models/requested_role.dart';
import '../../widgets/auth_page_shell.dart';

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key, required this.role});

  final RequestedRole role;

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: seriyaSoftTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_iphone_rounded,
              color: seriyaTeal,
              size: 38,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Registration submitted',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: seriyaNavy,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your ${role.title.toLowerCase()} account is awaiting administrator approval.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: seriyaNavy.withValues(alpha: 0.62),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F7),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Column(
              children: [
                _ApprovalStep(
                  number: '1',
                  text: 'The administrator verifies your employee details.',
                ),
                SizedBox(height: 13),
                _ApprovalStep(
                  number: '2',
                  text: 'Your route and vehicle are assigned.',
                ),
                SizedBox(height: 13),
                _ApprovalStep(
                  number: '3',
                  text: 'You receive approval and can sign in.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          AuthPrimaryButton(
            label: 'Back to sign in',
            icon: Icons.login_rounded,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

class _ApprovalStep extends StatelessWidget {
  const _ApprovalStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: seriyaSoftTeal,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: seriyaTeal,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: seriyaNavy,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
