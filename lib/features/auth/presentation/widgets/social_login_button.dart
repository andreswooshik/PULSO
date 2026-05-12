import 'package:flutter/material.dart';

/// Auth-feature specific widget for social login buttons
class SocialLoginButton extends StatelessWidget {
  final String provider; // 'google', 'github', 'apple'
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: _getProviderIcon(),
      label: Text('Sign in with ${provider.capitalize}'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _getProviderIcon() {
    return Icon(
      provider == 'google'
          ? Icons.g_mobiledata
          : provider == 'github'
              ? Icons.code
              : Icons.apple,
    );
  }
}

extension StringExtension on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
}
