import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_models.dart';
import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';

class ActionLogScreen extends ConsumerWidget {
  const ActionLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(adminActionLogProvider);

    return RefreshIndicator(
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
                onTap: () => _showEntryDetail(context, entry),
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
    );
  }

  void _showEntryDetail(BuildContext context, ActionLogEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Action details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.description),
            const SizedBox(height: 12),
            if (entry.actorName != null) Text('By: ${entry.actorName}'),
            Text('When: ${formatDateTime(entry.createdAt)}'),
            if (entry.actionType != null) Text('Action type: ${entry.actionType}'),
            if (entry.targetType != null && entry.targetId != null)
              Text('Target: ${entry.targetType} (${entry.targetId})'),
            if (entry.note != null && entry.note!.isNotEmpty) Text('Note: ${entry.note}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
