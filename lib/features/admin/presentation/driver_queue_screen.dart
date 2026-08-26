import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_models.dart';
import '../../../core/widgets/responsive_master_detail_list.dart';
import '../application/admin_providers.dart';
import 'driver_detail_screen.dart';

// GET /admin/drivers?status= only accepts approval-status values
// (pending/approved/rejected) per the backend's API reference — there is no
// "suspended" approval status to filter by. Suspended accounts still show
// up wherever their approval_status places them; the account-status badge
// on each row surfaces suspension separately.
/// One filter's worth of the driver queue — the filter itself now lives in
/// DriversShellScreen's bottom nav bar, this just renders a single status.
class DriverQueueScreen extends ConsumerWidget {
  const DriverQueueScreen({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(adminDriversProvider(status));

    return driversAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (drivers) {
        if (drivers.isEmpty) {
          return const Center(child: Text('No drivers in this state'));
        }
        final mobileList = RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminDriversProvider(status)),
          child: ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) => _DriverTile(driver: drivers[index]),
          ),
        );
        return ResponsiveMasterDetailList<AdminDriverSummary>(
          items: drivers,
          itemKey: (d) => d.id,
          mobileList: mobileList,
          detailFor: (d) => DriverDetailView(driverId: d.id),
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Status')),
          ],
          cellsFor: (d) => [
            DataCell(Text(d.fullName)),
            DataCell(Text(d.email)),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (d.accountStatus == 'suspended') ...[
                  const _StatusBadge(status: 'suspended'),
                  const SizedBox(width: 4),
                ],
                _StatusBadge(status: d.status),
              ],
            )),
          ],
        );
      },
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver});

  final AdminDriverSummary driver;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(driver.fullName),
      subtitle: Text(driver.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (driver.accountStatus == 'suspended') ...[
            const _StatusBadge(status: 'suspended'),
            const SizedBox(width: 4),
          ],
          _StatusBadge(status: driver.status),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DriverDetailScreen(driverId: driver.id)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      'suspended' => Colors.orange,
      _ => Colors.blueGrey,
    };
    return Chip(
      label: Text(status, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
