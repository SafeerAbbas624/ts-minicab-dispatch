import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';

class ActionLogScreen extends ConsumerWidget {
  const ActionLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(adminActionLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Action Log')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminActionLogProvider),
        child: logAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(error.toString())),
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(child: Text('No actions recorded yet'));
            }
            return ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  title: Text(entry.description),
                  subtitle: Text(
                    [
                      if (entry.actorName != null) entry.actorName!,
                      formatDateTime(entry.createdAt),
                    ].join(' · '),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
