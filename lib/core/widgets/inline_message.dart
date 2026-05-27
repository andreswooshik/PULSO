import 'package:flutter/material.dart';
import 'package:pulso/core/theme/app_theme.dart';

class InlineMessage extends StatelessWidget {
  final String message;

  const InlineMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.midnight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
