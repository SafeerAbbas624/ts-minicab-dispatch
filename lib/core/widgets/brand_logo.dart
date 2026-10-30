import 'package:flutter/material.dart';

/// The TS Minicab logo in the right colours for the current theme: the
/// original navy artwork on light backgrounds, an off-white version
/// (assets/branding/logo_dark.png, orange kept) in dark mode, where the navy
/// would disappear.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/branding/logo_dark.png' : 'assets/branding/logo.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'TS Minicab',
    );
  }
}
