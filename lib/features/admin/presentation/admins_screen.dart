import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_models.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';
import 'create_admin_screen.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAdmins();
});

/// super_admin only: every operator account, with its dispatcher name.
class AdminsScreen extends ConsumerWidget {
  const AdminsScreen({super.key});

  Future<void> _rename(BuildContext context, WidgetRef ref, AdminUser admin) async {
    final controller = TextEditingController(text: admin.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dispatcher name for ${admin.email}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Dispatcher name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    await _run(context, ref, () => ref.read(adminRepositoryProvider).renameAdmin(admin.id, name));
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, AdminUser admin) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${admin.label}?'),
        content: const Text('They will no longer be able to sign in to the admin panel.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, ref, () => ref.read(adminRepositoryProvider).deleteAdmin(admin.id));
  }

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(adminUsersProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminsAsync = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admins')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'adminsCreateFab',
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateAdminScreen()));
          ref.invalidate(adminUsersProvider);
        },
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New admin'),
      ),
      body: adminsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (admins) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: admins.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final a = admins[i];
            return ListTile(
              leading: CircleAvatar(child: Text(a.label.characters.first.toUpperCase())),
              title: Text(a.displayName ?? '(no dispatcher name)'),
              subtitle: Text('${a.email} · ${a.isSuperAdmin ? 'Super admin' : a.role == 'demo_admin' ? 'Demo admin' : 'Admin'}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => v == 'rename' ? _rename(context, ref, a) : _delete(context, ref, a),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'rename', child: Text('Change dispatcher name')),
                  if (!a.isSuperAdmin && a.role != 'demo_admin')
                    const PopupMenuItem(value: 'delete', child: Text('Remove admin')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
