import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_models.dart';
import '../application/admin_providers.dart';
import 'driver_detail_screen.dart';

const _statusFilters = [
  (null, 'All'),
  ('pending', 'Pending'),
  ('approved', 'Approved'),
  ('rejected', 'Rejected'),
  ('suspended', 'Suspended'),
];

class DriverQueueScreen extends ConsumerStatefulWidget {
  const DriverQueueScreen({super.key});

  @override
  ConsumerState<DriverQueueScreen> createState() => _DriverQueueScreenState();
}

class _DriverQueueScreenState extends ConsumerState<DriverQueueScreen> {
  String? _status = 'pending';

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(adminDriversProvider(_status));

    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _statusFilters.map((f) {
                final (value, label) = f;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _status == value,
                    onSelected: (_) => setState(() => _status = value),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: driversAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(error.toString())),
              data: (drivers) {
                if (drivers.isEmpty) {
                  return const Center(child: Text('No drivers in this state'));
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminDriversProvider(_status)),
                  child: ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (context, index) => _DriverTile(driver: drivers[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
      trailing: _StatusBadge(status: driver.status),
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
