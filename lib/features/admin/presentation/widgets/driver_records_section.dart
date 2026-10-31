import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/admin_driver_detail.dart';
import '../../../../core/models/records_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';
import '../records/record_widgets.dart';

/// Asks why the driver is stopping (TfL driver record "date of leaving").
/// Returns (reason, note) or null if cancelled.
Future<(String, String?)?> askLeaveReason(BuildContext context) {
  var reason = 'resigned';
  final note = TextEditingController();
  return showDialog<(String, String?)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Suspend driver'),
        content: SizedBox(
          width: 440,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Why is this driver stopping? This is recorded as their date of leaving.'),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: reason,
              onChanged: (v) => setState(() => reason = v!),
              child: Column(children: [
                for (final e in leaveReasons.entries)
                  RadioListTile<String>(contentPadding: EdgeInsets.zero, value: e.key, title: Text(e.value)),
              ]),
            ),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)'), maxLines: 2),
            if (reason == 'conduct')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'TfL must be told within 14 days on form PHV/105. You\'ll get an email now and a reminder before the deadline.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop((reason, note.text.trim().isEmpty ? null : note.text.trim())),
            child: const Text('Suspend'),
          ),
        ],
      ),
    ),
  );
}

/// Availability history, former vehicles and the printable TfL records.
class DriverRecordsSection extends ConsumerWidget {
  const DriverRecordsSection({super.key, required this.driverId, required this.detail});

  final String driverId;
  final AdminDriverDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(adminRepositoryProvider);
    final t = Theme.of(context).textTheme;
    final name = detail.driver.fullName.replaceAll(' ', '-');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text('TfL driver record', style: t.titleMedium)),
          TextButton.icon(
            onPressed: () => downloadRecord(context, () => repo.fetchDriverRecordPdf(driverId), 'driver-record-$name.pdf', 'application/pdf'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Driver record PDF'),
          ),
        ]),
        if (detail.erasureDueAt != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Account closed by the driver. Record kept until ${formatDate(detail.erasureDueAt!)}, then erased automatically.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        if (detail.availability.isEmpty) const Text('Not yet available — dates start when the driver is approved.'),
        for (final p in detail.availability) _PeriodTile(driverId: driverId, period: p),
        const SizedBox(height: 12),
        Text('Vehicles', style: t.titleSmall),
        for (final v in detail.vehicles)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(v.isActive ? Icons.directions_car : Icons.history),
            title: Text('${v.registration ?? '—'} · ${v.description}'),
            subtitle: Text([
              'From ${v.availableFrom != null ? formatDate(v.availableFrom!) : '—'}',
              if (v.ceasedAt != null) 'ceased ${formatDate(v.ceasedAt!)}' else if (v.isActive) 'in service',
              'keeper: ${v.keeperName ?? (v.ownedByDriver ? 'driver' : 'not recorded')}',
            ].join(' · ')),
            trailing: IconButton(
              tooltip: 'Vehicle record PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => downloadRecord(context, () => repo.fetchVehicleRecordPdf(v.id), 'vehicle-record-${v.registration ?? v.id}.pdf', 'application/pdf'),
            ),
          ),
      ],
    );
  }
}

class _PeriodTile extends ConsumerWidget {
  const _PeriodTile({required this.driverId, required this.period});
  final String driverId;
  final AvailabilityPeriod period;

  Future<void> _patch(BuildContext context, WidgetRef ref, Map<String, dynamic> changes) async {
    try {
      await ref.read(adminRepositoryProvider).updateAvailability(driverId, period.id, changes);
      ref.invalidate(adminDriverDetailProvider(driverId));
      ref.invalidate(adminComplianceSummaryProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, String key, DateTime? initial, String help) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
      helpText: help,
    );
    if (picked != null && context.mounted) await _patch(context, ref, {key: picked.toUtc().toIso8601String()});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = period;
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                '${formatDate(p.startedAt)} → ${p.endedAt != null ? formatDate(p.endedAt!) : 'still available'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Correct dates',
              onSelected: (k) => k == 'start'
                  ? _pickDate(context, ref, 'started_at', p.startedAt, 'Date available from')
                  : _pickDate(context, ref, 'ended_at', p.endedAt, 'Date of leaving'),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'start', child: Text('Change start date')),
                if (p.endedAt != null) const PopupMenuItem(value: 'end', child: Text('Change leaving date')),
              ],
            ),
          ]),
          if (p.endReasonLabel != null) Text('${p.endReasonLabel}${p.endNote != null ? ' — ${p.endNote}' : ''}'),
          if (p.phv105DueAt != null)
            p.reportedToTflAt != null
                ? Text('Reported to TfL on ${formatDate(p.reportedToTflAt!)}', style: TextStyle(color: colors.primary))
                : Row(children: [
                    Expanded(
                      child: Text(
                        'PHV/105 to TfL due by ${formatDate(p.phv105DueAt!)}',
                        style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickDate(context, ref, 'reported_to_tfl_at', DateTime.now(), 'Date reported to TfL'),
                      child: const Text('Mark reported'),
                    ),
                  ]),
        ]),
      ),
    );
  }
}
