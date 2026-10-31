import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/records_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';
import 'record_widgets.dart';

/// Complaints & compliments record (TfL regulation 14), laid out like the
/// inspector's Complaint/Compliment form.
class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminComplaintsProvider);
    final repo = ref.read(adminRepositoryProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newComplaintFab',
        onPressed: () => _open(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Log complaint'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminComplaintsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    '${items.where((c) => c.isOpen && !c.isCompliment).length} open · ${items.length} total · kept 12 months',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => downloadRecord(context, repo.fetchComplaintsCsv, 'ts-minicab-complaints.csv', 'text/csv;charset=utf-8'),
                  icon: const Icon(Icons.download),
                  label: const Text('CSV'),
                ),
              ]),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('No complaints recorded. Website reports and ones you log appear here.')),
                ),
              for (final c in items)
                Card(
                  child: ListTile(
                    leading: Icon(c.isCompliment ? Icons.thumb_up_alt_outlined : Icons.report_outlined),
                    title: Text('${c.ref} · ${c.complainantName}'),
                    subtitle: Text(
                      '${formatDateTime(c.receivedAt)}${c.bookingRef != null ? ' · ${c.bookingRef}' : ''}'
                      '${c.source == 'website' ? ' · via website' : ''}\n${c.details}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: OpenClosedChip(open: c.isOpen),
                    onTap: () => _open(context, ref, c),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Complaint? c) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComplaintEditor(complaint: c)));
    ref.invalidate(adminComplaintsProvider);
    ref.invalidate(adminComplianceSummaryProvider);
  }
}

class ComplaintEditor extends ConsumerStatefulWidget {
  const ComplaintEditor({super.key, this.complaint});
  final Complaint? complaint;

  @override
  ConsumerState<ComplaintEditor> createState() => _ComplaintEditorState();
}

class _ComplaintEditorState extends ConsumerState<ComplaintEditor> {
  final _form = GlobalKey<FormState>();
  late final c = widget.complaint;
  late String _kind = c?.kind ?? 'complaint';
  late DateTime? _received = c?.receivedAt ?? DateTime.now();
  late final _ref = TextEditingController(text: c?.bookingRef);
  late final _name = TextEditingController(text: c?.complainantName);
  late final _address = TextEditingController(text: c?.address);
  late final _phone = TextEditingController(text: c?.phone);
  late final _email = TextEditingController(text: c?.email);
  late final _details = TextEditingController(text: c?.details);
  late final _investigation = TextEditingController(text: c?.investigation);
  late final _result = TextEditingController(text: c?.result);
  bool _saving = false;

  @override
  void dispose() {
    for (final t in [_ref, _name, _address, _phone, _email, _details, _investigation, _result]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save({bool close = false, bool reopen = false}) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'kind': _kind,
      'booking_ref': trimOrNull(_ref),
      'received_at': isoOrNull(_received),
      'complainant_name': _name.text.trim(),
      'address': trimOrNull(_address),
      'phone': trimOrNull(_phone),
      'email': trimOrNull(_email) ?? '',
      'details': _details.text.trim(),
      'investigation': trimOrNull(_investigation),
      'result': trimOrNull(_result),
      if (close) 'status': 'closed',
      if (reopen) 'status': 'open',
    };
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (c == null) {
        await repo.createComplaint(body);
      } else {
        await repo.updateComplaint(c!.id, body);
      }
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(adminRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(c == null ? 'Log complaint / compliment' : '${c!.ref} · ${c!.isCompliment ? 'Compliment' : 'Complaint'}'),
        actions: [
          if (c != null)
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => downloadRecord(context, () => repo.fetchComplaintPdf(c!.id), 'complaint-${c!.ref}.pdf', 'application/pdf'),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'complaint', label: Text('Complaint'), icon: Icon(Icons.report_outlined)),
                    ButtonSegment(value: 'compliment', label: Text('Compliment'), icon: Icon(Icons.thumb_up_alt_outlined)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (v) => setState(() => _kind = v.first),
                ),
                const SizedBox(height: 12),
                if (c != null)
                  Text(
                    'Handled by ${c!.handledBy ?? '—'}${c!.source == 'website' ? ' · received via the website form' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                DateTimeRow(label: 'Date complaint received', value: _received, onChanged: (v) => setState(() => _received = v)),
                RecordField(
                  controller: _ref,
                  label: 'Booking reference',
                  hint: 'e.g. TS-10003 — fills in the booking date, driver and vehicle',
                  caps: true,
                ),
                if (c?.bookingAt != null || c?.driverName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Booking ${c!.bookingAt != null ? formatDateTime(c!.bookingAt!) : ''} · Driver ${c!.driverName ?? '—'} · Vehicle ${c!.vehicleReg ?? '—'}',
                    ),
                  ),
                const SectionTitle('Details of complainant'),
                RecordField(controller: _name, label: 'Name', required: true),
                RecordField(controller: _address, label: 'Address', maxLines: 2),
                RecordField(controller: _phone, label: 'Phone No', keyboard: TextInputType.phone),
                RecordField(controller: _email, label: 'Email', keyboard: TextInputType.emailAddress),
                const SectionTitle('Details of complaint'),
                RecordField(controller: _details, label: 'What happened', required: true, maxLines: 5),
                const SectionTitle('Method / enquiry to resolve complaint'),
                RecordField(controller: _investigation, label: 'Investigation and action taken', maxLines: 5),
                const SectionTitle('Result'),
                RecordField(controller: _result, label: 'Outcome', hint: 'Required before closing', maxLines: 3),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton(onPressed: _saving ? null : () => _save(), child: const Text('Save')),
                  if (c == null || c!.isOpen)
                    OutlinedButton(onPressed: _saving ? null : () => _save(close: true), child: const Text('Save and close')),
                  if (c != null && !c!.isOpen)
                    OutlinedButton(onPressed: _saving ? null : () => _save(reopen: true), child: const Text('Reopen')),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
