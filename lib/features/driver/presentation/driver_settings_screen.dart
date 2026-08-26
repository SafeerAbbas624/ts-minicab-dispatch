import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/presentation/privacy_policy_screen.dart';
import '../../auth/presentation/terms_conditions_screen.dart';
import '../application/driver_providers.dart';
import '../data/driver_repository.dart';
import 'bank_details_screen.dart';
import 'delete_account_screen.dart';
import 'documents_screen.dart';

class DriverSettingsScreen extends ConsumerWidget {
  const DriverSettingsScreen({super.key});

  /// PATCH /drivers/me only accepts avatar_url as a plain string field —
  /// confirmed via the backend's own API reference, there is no file-upload
  /// endpoint for avatars at all. So this sets a URL rather than picking a
  /// local image file, which is a real capability limit, not a UI choice.
  Future<void> _setAvatarUrl(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Avatar URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Image URL'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    try {
      await ref.read(driverRepositoryProvider).updateMe(avatarUrl: url);
      ref.invalidate(driverMeProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newPassword == null || newPassword.length < 8) {
      if (newPassword != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 8 characters')),
        );
      }
      return;
    }
    try {
      await ref.read(driverRepositoryProvider).updateMe(password: newPassword);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Password updated')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(driverMeProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        driverAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text(error.toString()),
          data: (driver) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    driver.avatarUrl != null ? NetworkImage(driver.avatarUrl!) : null,
                child: driver.avatarUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(driver.fullName),
              subtitle: Text(driver.email),
              trailing: TextButton(
                onPressed: () => _setAvatarUrl(context, ref),
                child: const Text('Set photo URL'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Documents'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: const Text('Bank Details'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BankDetailsScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                onTap: () => _changePassword(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Request Account Deletion',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
            ),
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
