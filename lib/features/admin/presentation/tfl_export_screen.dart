import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

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
      final dir = await getTemporaryDirectory();
      final weekLabel =
          '${_weekStart.year}-${_weekStart.month.toString().padLeft(2, '0')}-${_weekStart.day.toString().padLeft(2, '0')}';
      final file = File('${dir.path}/tfl-export-$weekLabel.csv');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: 'TfL export $weekLabel'),
      );
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
    if (rows.isEmpty) return const Center(child: Text('No data for this week'));

    final columns = rows.first.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: columns.map((c) => DataCell(Text('${row[c] ?? ''}'))).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
