import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/csv_export.dart';
import '../../../core/utils/formatters.dart';
import '../data/admin_repository.dart';

// Same headings as the CSV, which follows the layout TfL's compliance
// inspector asked for (booking ref is shown here only, for finding a job).
const _tflColumnLabels = {
  'booking_ref': 'Booking',
  'accepted_by': 'Person accepting booking',
  'booked_at': 'Date of booking',
  'journey_at': 'Date of journey',
  'customer_name': 'Customer name',
  'telephone': 'Telephone number',
  'collection': 'Place of collection',
  'destination': 'Main destination',
  'fare_quoted': 'Fare quoted',
  'dispatched_by': 'Person dispatching booking',
  'driver': 'Driver full name and PHV licence number',
  'vehicle_reg': 'Vehicle reg.',
  'sublet': 'Sublet - Op No. & Name',
};

DateTime _mostRecentMonday(DateTime from) => from.subtract(Duration(days: from.weekday - 1));

class TflExportScreen extends ConsumerStatefulWidget {
  const TflExportScreen({super.key});

  @override
  ConsumerState<TflExportScreen> createState() => _TflExportScreenState();
}

class _TflExportScreenState extends ConsumerState<TflExportScreen> {
  late DateTime _weekStart = _mostRecentMonday(DateTime.now());
  List<Map<String, dynamic>>? _rows;
  bool _isLoading = false;
  bool _isExporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await ref.read(adminRepositoryProvider).fetchTflExport(weekStart: _weekStart);
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _weekStart = _mostRecentMonday(picked));
    _load();
  }

  Future<void> _downloadCsv() async {
    setState(() => _isExporting = true);
    try {
      final bytes =
          await ref.read(adminRepositoryProvider).fetchTflExportCsv(weekStart: _weekStart);
      final weekLabel = dateOnly(_weekStart);
      if (!mounted) return;
      await shareCsv(bytes, 'ts-minicab-bookings-$weekLabel.csv', subject: 'TS Minicab bookings w/c $weekLabel');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekLabel =
        '${_weekStart.year}-${_weekStart.month.toString().padLeft(2, '0')}-${_weekStart.day.toString().padLeft(2, '0')}';

    // This screen is a drawer tab inside AdminShell's own Scaffold, not a
    // pushed route — no nested Scaffold here, so the FAB is positioned by
    // hand via Stack/Align instead of Scaffold's floatingActionButton slot.
    return Stack(
      children: [
        Column(
          children: [
            ListTile(
              title: Text('Week starting $weekLabel'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickWeek,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            // admin_shell.dart keeps every top-level screen mounted at once via
            // IndexedStack, so this FAB coexists in the tree with
            // JobsShellScreen's — without a unique tag both fall back to
            // Flutter's shared default FloatingActionButton hero tag and collide.
            heroTag: 'tflExportDownloadFab',
            onPressed: _isExporting ? null : _downloadCsv,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: const Text('Download CSV'),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final rows = _rows ?? [];
    if (rows.isEmpty) return const Center(child: Text('No bookings this week'));

    final columns = rows.first.keys.where((c) => c != 'job_id').toList();
    String cell(String column, dynamic value) {
      if (value == null) return '';
      if (column.endsWith('_at') || column.endsWith('_datetime')) {
        final dt = DateTime.tryParse(value.toString());
        if (dt != null) return formatDateTime(dt);
      }
      return '$value';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns.map((c) => DataColumn(label: Text(_tflColumnLabels[c] ?? c))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: columns.map((c) => DataCell(Text(cell(c, row[c])))).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
