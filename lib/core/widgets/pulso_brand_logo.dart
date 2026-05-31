import 'package:flutter/material.dart';

class PulsoBrandLogo extends StatelessWidget {
  final bool compact;
  final double? width;
  final double height;
  final BoxFit fit;

  const PulsoBrandLogo({
    super.key,
    this.compact = false,
    this.width,
    this.height = 64,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = compact
        ? 'assets/branding/pulso_mark.png'
        : 'assets/branding/pulso_wordmark.png';

    return Image.asset(assetPath, width: width, height: height, fit: fit);
  }
}
