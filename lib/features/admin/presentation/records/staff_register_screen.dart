import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/records_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_repository.dart';
import 'record_widgets.dart';

/// Register of everyone who takes bookings or dispatches vehicles (TfL
/// condition since 1 July 2024): full name, date of birth and the basic DBS
/// certificate seen. Columns match the inspector's Staff Register.
class StaffRegisterScreen extends ConsumerWidget {
  const StaffRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminStaffRegisterProvider);
    final me = ref.watch(adminMeProvider).valueOrNull;
    final isSuperAdmin = ref.watch(authControllerProvider).role?.isSuperAdmin ?? false;
    final repo = ref.read(adminRepositoryProvider);
    String day(DateTime? d) => d == null ? '—' : formatDate(d);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminStaffRegisterProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (staff) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              const Expanded(
                child: Text('Everyone who takes bookings or dispatches vehicles, including you. Kept 12 months after they stop.'),
              ),
              TextButton.icon(
                onPressed: () => downloadRecord(context, repo.fetchStaffRegisterCsv, 'ts-minicab-staff-register.csv', 'text/csv;charset=utf-8'),
                icon: const Icon(Icons.download),
                label: const Text('CSV'),
              ),
            ]),
            const SizedBox(height: 8),
            for (final s in staff)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(s.name, style: Theme.of(context).textTheme.titleMedium)),
                        if (s.isRemoved) const Chip(label: Text('Ceased'), visualDensity: VisualDensity.compact),
                        if (isSuperAdmin || s.id == me?.id)
                          TextButton.icon(
                            onPressed: () => _edit(context, ref, s, me: s.id == me?.id),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                      ]),
                      Text(s.email, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(spacing: 24, runSpacing: 4, children: [
                        _kv('Date of entry', day(s.enteredAt)),
                        _kv('Date of birth', day(s.dateOfBirth)),
                        _kv('DBS certificate no.', s.dbsCertificateNumber ?? '—'),
                        _kv('DBS issued', day(s.dbsIssueDate)),
                        _kv('DBS seen', day(s.dbsSeenDate)),
                        _kv('Ceased', day(s.ceasedAt)),
                      ]),
                      if (s.missing.isNotEmpty && !s.isRemoved)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Missing: ${s.missing.join(', ')}',
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [Text(k, style: const TextStyle(fontSize: 12)), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
      );

  Future<void> _edit(BuildContext context, WidgetRef ref, StaffRegisterEntry s, {required bool me}) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _StaffRegisterDialog(entry: s, me: me));
    if (saved == true) {
      ref.invalidate(adminStaffRegisterProvider);
      ref.invalidate(adminComplianceSummaryProvider);
    }
  }
}

class _StaffRegisterDialog extends ConsumerStatefulWidget {
  const _StaffRegisterDialog({required this.entry, required this.me});
  final StaffRegisterEntry entry;
  final bool me;

  @override
  ConsumerState<_StaffRegisterDialog> createState() => _StaffRegisterDialogState();
}

class _StaffRegisterDialogState extends ConsumerState<_StaffRegisterDialog> {
  late final _name = TextEditingController(text: widget.entry.fullName ?? widget.entry.displayName);
  late final _dbs = TextEditingController(text: widget.entry.dbsCertificateNumber);
  late DateTime? _dob = widget.entry.dateOfBirth;
  late DateTime? _issued = widget.entry.dbsIssueDate;
  late DateTime? _seen = widget.entry.dbsSeenDate;
  late DateTime? _entered = widget.entry.enteredAt;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dbs.dispose();
    super.dispose();
  }

  String? _day(DateTime? d) => d == null ? null : dateOnly(d);

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).updateStaffRegister(
        widget.entry.id,
        {
          'full_name': trimOrNull(_name),
          'date_of_birth': _day(_dob),
          'dbs_certificate_number': trimOrNull(_dbs),
          'dbs_issue_date': _day(_issued),
          'dbs_seen_date': _day(_seen),
          'entered_at': ?_day(_entered),
        },
        me: widget.me,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Staff register — ${widget.entry.name}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            RecordField(controller: _name, label: 'Full name (as on ID)', required: true),
            DateTimeRow(label: 'Date of birth', value: _dob, withTime: false, onChanged: (v) => setState(() => _dob = v)),
            RecordField(controller: _dbs, label: 'Basic DBS certificate number', hint: 'Top right of the certificate'),
            DateTimeRow(label: 'DBS certificate date of issue', value: _issued, withTime: false, onChanged: (v) => setState(() => _issued = v)),
            DateTimeRow(label: 'Date you saw the DBS certificate', value: _seen, withTime: false, onChanged: (v) => setState(() => _seen = v)),
            DateTimeRow(label: 'Date of entry on the register', value: _entered, withTime: false, onChanged: (v) => setState(() => _entered = v)),
            const SizedBox(height: 8),
            Text(
              'TfL recommends the certificate is no more than 4 months old when someone is added. Don\'t keep a copy — return it to the person.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
