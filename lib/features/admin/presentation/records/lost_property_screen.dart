import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/records_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';
import 'record_widgets.dart';

/// Lost and found property record (TfL regulation 15), laid out like the
/// inspector's Lost/Found Property form.
class LostPropertyScreen extends ConsumerWidget {
  const LostPropertyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminLostPropertyProvider);
    final repo = ref.read(adminRepositoryProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'newLostPropertyFab',
        onPressed: () => _open(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Log item'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminLostPropertyProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(children: [
                Expanded(child: Text('${items.where((i) => i.isOpen).length} open · ${items.length} total · kept 12 months')),
                TextButton.icon(
                  onPressed: () => downloadRecord(context, repo.fetchLostPropertyCsv, 'ts-minicab-lost-property.csv', 'text/csv;charset=utf-8'),
                  icon: const Icon(Icons.download),
                  label: const Text('CSV'),
                ),
              ]),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('No lost or found property recorded.')),
                ),
              for (final i in items)
                Card(
                  child: ListTile(
                    leading: Icon(i.isFound ? Icons.inventory_2_outlined : Icons.search),
                    title: Text('${i.ref} · ${i.isFound ? 'Found' : 'Reported lost'}${i.vehicleReg != null ? ' · ${i.vehicleReg}' : ''}'),
                    subtitle: Text(
                      '${formatDateTime(i.receivedAt)}${i.customerName != null ? ' · ${i.customerName}' : ''}'
                      '${i.source == 'website' ? ' · via website' : ''}\n${i.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: OpenClosedChip(open: i.isOpen),
                    onTap: () => _open(context, ref, i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, LostPropertyItem? i) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LostPropertyEditor(item: i)));
    ref.invalidate(adminLostPropertyProvider);
    ref.invalidate(adminComplianceSummaryProvider);
  }
}

class LostPropertyEditor extends ConsumerStatefulWidget {
  const LostPropertyEditor({super.key, this.item});
  final LostPropertyItem? item;

  @override
  ConsumerState<LostPropertyEditor> createState() => _LostPropertyEditorState();
}

class _LostPropertyEditorState extends ConsumerState<LostPropertyEditor> {
  final _form = GlobalKey<FormState>();
  late final i = widget.item;
  late String _kind = i?.kind ?? 'found';
  late DateTime? _received = i?.receivedAt ?? DateTime.now();
  late DateTime? _lostAt = i?.lostAt;
  late final _ref = TextEditingController(text: i?.bookingRef);
  late final _handedIn = TextEditingController(text: i?.handedInBy);
  late final _place = TextEditingController(text: i?.place);
  late final _vrm = TextEditingController(text: i?.vehicleReg);
  late final _name = TextEditingController(text: i?.customerName);
  late final _address = TextEditingController(text: i?.address);
  late final _phone = TextEditingController(text: i?.phone);
  late final _email = TextEditingController(text: i?.email);
  late final _description = TextEditingController(text: i?.description);
  late final _actions = TextEditingController(text: i?.actionsTaken);
  late final _result = TextEditingController(text: i?.result);
  late final _disposal = TextEditingController(text: i?.disposal);
  bool _saving = false;

  @override
  void dispose() {
    for (final t in [_ref, _handedIn, _place, _vrm, _name, _address, _phone, _email, _description, _actions, _result, _disposal]) {
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
      'lost_at': isoOrNull(_lostAt),
      'handed_in_by': trimOrNull(_handedIn),
      'place': trimOrNull(_place),
      'vehicle_reg': trimOrNull(_vrm)?.toUpperCase(),
      'customer_name': trimOrNull(_name),
      'address': trimOrNull(_address),
      'phone': trimOrNull(_phone),
      'email': trimOrNull(_email) ?? '',
      'description': _description.text.trim(),
      'actions_taken': trimOrNull(_actions),
      'result': trimOrNull(_result),
      'disposal': trimOrNull(_disposal),
      if (close) 'status': 'closed',
      if (reopen) 'status': 'open',
    };
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (i == null) {
        await repo.createLostProperty(body);
      } else {
        await repo.updateLostProperty(i!.id, body);
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
    final found = _kind == 'found';
    return Scaffold(
      appBar: AppBar(
        title: Text(i == null ? 'Log lost / found property' : '${i!.ref} · ${i!.isFound ? 'Found' : 'Reported lost'}'),
        actions: [
          if (i != null)
            IconButton(
              tooltip: 'Download PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => downloadRecord(context, () => repo.fetchLostPropertyPdf(i!.id), 'lost-property-${i!.ref}.pdf', 'application/pdf'),
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
                    ButtonSegment(value: 'found', label: Text('Found in a vehicle / office'), icon: Icon(Icons.inventory_2_outlined)),
                    ButtonSegment(value: 'reported_lost', label: Text('Reported lost'), icon: Icon(Icons.search)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (v) => setState(() => _kind = v.first),
                ),
                const SizedBox(height: 12),
                if (i != null) Text('Handled by ${i!.handledBy ?? '—'}', style: Theme.of(context).textTheme.bodySmall),
                DateTimeRow(
                  label: found ? 'Date property received' : 'Date of report',
                  value: _received,
                  onChanged: (v) => setState(() => _received = v),
                ),
                if (!found) DateTimeRow(label: 'Date it was lost', value: _lostAt, onChanged: (v) => setState(() => _lostAt = v)),
                RecordField(controller: _ref, label: 'Booking reference', hint: 'e.g. TS-10003 — fills in the booking date and vehicle', caps: true),
                if (found) RecordField(controller: _handedIn, label: 'Handed in by', hint: 'e.g. the driver'),
                RecordField(controller: _place, label: found ? 'Where it was found' : 'Where it was lost', hint: 'e.g. back seat'),
                RecordField(controller: _vrm, label: 'Vehicle registration', caps: true),
                const SectionTitle('Customer details'),
                RecordField(controller: _name, label: 'Name'),
                RecordField(controller: _address, label: 'Address', maxLines: 2),
                RecordField(controller: _phone, label: 'Phone No', keyboard: TextInputType.phone),
                RecordField(controller: _email, label: 'Email', keyboard: TextInputType.emailAddress),
                const SectionTitle('Details of property'),
                RecordField(controller: _description, label: 'Description of the item', required: true, maxLines: 3),
                SectionTitle(found ? 'Method / enquiry to return property' : 'Steps taken to find the item'),
                RecordField(controller: _actions, label: 'What was done, and when', maxLines: 4),
                const SectionTitle('Result'),
                RecordField(controller: _result, label: 'Result', hint: 'e.g. returned to owner on 02/11 by driver', maxLines: 2),
                RecordField(controller: _disposal, label: 'If unclaimed and disposed of, how', maxLines: 2),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton(onPressed: _saving ? null : () => _save(), child: const Text('Save')),
                  if (i == null || i!.isOpen)
                    OutlinedButton(onPressed: _saving ? null : () => _save(close: true), child: const Text('Save and close')),
                  if (i != null && !i!.isOpen)
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
