import 'package:flutter/material.dart';

/// Auth-feature specific widget showing password requirements
class PasswordValidationHint extends StatelessWidget {
  final String password;

  const PasswordValidationHint({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ValidationItem(met: hasMinLength, text: 'At least 8 characters'),
        _ValidationItem(
          met: hasUppercase,
          text: 'At least one uppercase letter',
        ),
        _ValidationItem(
          met: hasLowercase,
          text: 'At least one lowercase letter',
        ),
        _ValidationItem(met: hasDigits, text: 'At least one number'),
        _ValidationItem(
          met: hasSpecialChar,
          text: 'At least one special character',
        ),
      ],
    );
  }
}

class _ValidationItem extends StatelessWidget {
  final bool met;
  final String text;

  const _ValidationItem({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: met ? Colors.green : Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
