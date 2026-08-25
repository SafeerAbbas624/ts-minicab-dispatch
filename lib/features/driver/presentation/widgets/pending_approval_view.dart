import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../application/driver_providers.dart';

/// Shown in place of the Jobs tab whenever a job-related endpoint 403s with
/// a not-approved/suspended/rejected message. The backend signals this
/// per-request rather than via a status field, so [message] is whatever the
/// server actually sent rather than a fixed enum of copy. Still reachable
/// from a full DriverShell (Settings > Documents works normally) — this is
/// scoped to the Jobs tab only, not a full-screen block.
class PendingApprovalView extends ConsumerWidget {
  const PendingApprovalView({super.key, required this.message, required this.onRefresh});

  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Haven't uploaded your documents yet? Go to Settings > Documents "
              "to upload them — we can't approve your account until we've "
              'reviewed them.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(driverTabIndexProvider.notifier).state = 3,
              icon: const Icon(Icons.upload_file),
              label: const Text('Go to Settings'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Check again'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
