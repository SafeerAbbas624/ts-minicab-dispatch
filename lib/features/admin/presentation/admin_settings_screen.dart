import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/forgot_password_screen.dart';
import '../../auth/presentation/privacy_policy_screen.dart';
import '../../auth/presentation/terms_conditions_screen.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (mode) => ref.read(themeControllerProvider.notifier).setThemeMode(mode!),
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(title: Text('System theme'), value: ThemeMode.system),
                RadioListTile<ThemeMode>(title: Text('Light'), value: ThemeMode.light),
                RadioListTile<ThemeMode>(title: Text('Dark'), value: ThemeMode.dark),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Reset Password'),
            subtitle: const Text('Sends a reset link to your email'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Terms & Conditions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
      ],
    );
  }
}
