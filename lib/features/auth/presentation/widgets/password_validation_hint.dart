import 'package:flutter/material.dart';

class PasswordValidationState {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigits;
  final bool hasSpecialChar;

  const PasswordValidationState({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigits,
    required this.hasSpecialChar,
  });

  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigits &&
      hasSpecialChar;
}

class PasswordPolicy {
  static PasswordValidationState evaluate(String password) {
    return PasswordValidationState(
      hasMinLength: password.length >= 8,
      hasUppercase: password.contains(RegExp(r'[A-Z]')),
      hasLowercase: password.contains(RegExp(r'[a-z]')),
      hasDigits: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    );
  }
}

/// Auth-feature specific widget showing password requirements
class PasswordValidationHint extends StatelessWidget {
  final String password;

  const PasswordValidationHint({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final validationState = PasswordPolicy.evaluate(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ValidationItem(
          met: validationState.hasMinLength,
          text: 'At least 8 characters',
        ),
        _ValidationItem(
          met: validationState.hasUppercase,
          text: 'At least one uppercase letter',
        ),
        _ValidationItem(
          met: validationState.hasLowercase,
          text: 'At least one lowercase letter',
        ),
        _ValidationItem(
          met: validationState.hasDigits,
          text: 'At least one number',
        ),
        _ValidationItem(
          met: validationState.hasSpecialChar,
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
