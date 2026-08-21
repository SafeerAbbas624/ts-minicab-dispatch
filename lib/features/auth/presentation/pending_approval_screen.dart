import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/driver.dart';
import '../application/auth_controller.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await ref.read(authControllerProvider.notifier).refreshDriverApprovalStatus();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).driverApprovalStatus;
    final isRejectedOrSuspended =
        status == DriverApprovalStatus.rejected || status == DriverApprovalStatus.suspended;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Status'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRejectedOrSuspended ? Icons.block : Icons.hourglass_top,
                size: 64,
                color: isRejectedOrSuspended
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                switch (status) {
                  DriverApprovalStatus.rejected => 'Your application was not approved',
                  DriverApprovalStatus.suspended => 'Your account is suspended',
                  _ => 'Your application is pending approval',
                },
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isRejectedOrSuspended
                    ? 'Contact TS Minicab support for more information.'
                    : 'An admin needs to review your documents before you can start '
                        'accepting jobs. Check back soon.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (!isRejectedOrSuspended)
                FilledButton.icon(
                  onPressed: _isRefreshing ? null : _refresh,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Check status'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
