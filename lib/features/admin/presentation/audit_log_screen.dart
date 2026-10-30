import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/csv_export.dart';
import '../data/admin_repository.dart';

/// Every step of every booking with a millisecond timestamp — the
/// "timestamped log" TfL asks to see at the technical demonstration. Search
/// by booking reference to show one booking's whole journey in order.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key, this.initialRef});

  final String? initialRef;

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  late final _refController = TextEditingController(text: widget.initialRef);
  List<AuditLogEntry>? _entries;
  String? _error;
  bool _loading = false;
  bool _exporting = false;

  // Without a booking ref, default to the last 7 days so the list stays small.
  DateTime? get _from => _refController.text.trim().isEmpty ? DateTime.now().subtract(const Duration(days: 7)) : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await ref
          .read(adminRepositoryProvider)
          .fetchAuditLog(bookingRef: _refController.text.trim(), from: _from);
      if (mounted) setState(() => _entries = entries);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final ref_ = _refController.text.trim();
      final bytes = await ref.read(adminRepositoryProvider).fetchAuditLogCsv(bookingRef: ref_, from: _from);
      await shareCsv(bytes, ref_.isEmpty ? 'booking-audit-log.csv' : 'booking-audit-log-$ref_.csv',
          subject: 'TS Minicab booking audit log');
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _refController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Booking reference',
                    hintText: 'e.g. TS-10001 (blank = last 7 days)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _load),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Export CSV',
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
              ),
            ],
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading && _entries == null) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final entries = _entries ?? [];
    if (entries.isEmpty) return const Center(child: Text('No booking events found'));
    final mono = Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: entries.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final e = entries[i];
          return ListTile(
            dense: true,
            title: Text('${e.bookingRef} · ${e.eventLabel}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.timestampDisplay, style: mono),
                Text(e.actor),
                if (e.note != null && e.note!.isNotEmpty) Text(e.note!, maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              _refController.text = e.bookingRef;
              _load();
            },
          );
        },
      ),
    );
  }
}
