import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Same navy ground and white logo as the login screen, so launch flows
/// straight into sign-in without a flash of a different colour.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? Theme.of(context).colorScheme.surface : Brand.navy800,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/branding/logo_dark.png'),
              height: 120,
              fit: BoxFit.contain,
              semanticLabel: 'TS Minicab',
            ),
            SizedBox(height: 28),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3, color: Brand.orange),
            ),
          ],
        ),
      ),
    );
  }
}
