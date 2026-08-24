import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/admin_models.dart';
import '../../application/admin_providers.dart';

/// Search-and-pick dialog for assigning a job to a specific driver. Returns
/// the selected driver, or `null` if the admin dismissed without picking
/// one. When [onReopenToPool] is given, a "Reopen to general pool" option is
/// pinned at the top too — for a job that already has a driver, this is an
/// alternative to picking a specific one (distinguished by [onReopenToPool]
/// having been called instead of the dialog returning a driver); omit it for
/// an open job, where there's no current driver to unassign. Searches by
/// name, email, or phone number.
Future<AdminDriverSummary?> showDriverPickerDialog(
  BuildContext context, {
  VoidCallback? onReopenToPool,
  String title = 'Assign driver',
}) {
  return showDialog<AdminDriverSummary>(
    context: context,
    builder: (context) => _DriverPickerDialog(onReopenToPool: onReopenToPool, title: title),
  );
}

class _DriverPickerDialog extends ConsumerStatefulWidget {
  const _DriverPickerDialog({required this.onReopenToPool, required this.title});

  final VoidCallback? onReopenToPool;
  final String title;

  @override
  ConsumerState<_DriverPickerDialog> createState() => _DriverPickerDialogState();
}

class _DriverPickerDialogState extends ConsumerState<_DriverPickerDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(adminDriversProvider('approved'));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search drivers by name, email, or number',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            if (widget.onReopenToPool != null) ...[
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Reopen to general pool'),
                subtitle: const Text('Any approved driver can accept it'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onReopenToPool!();
                },
              ),
              const Divider(height: 1),
            ],
            Flexible(
              child: driversAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$error'),
                ),
                data: (drivers) {
                  // adminDriversProvider('approved') filters on
                  // *approval* status only — a suspended driver's account
                  // can independently still read approval_status: approved
                  // (confirmed earlier this session), so exclude suspended
                  // accounts here too rather than offering to hand them a
                  // job they can't actually work.
                  final assignable = drivers.where((d) => d.accountStatus != 'suspended');
                  // Phone numbers are matched digit-only so a query like
                  // "7700900123" matches a stored "+447700900123" without
                  // the admin having to type the country code / punctuation.
                  final queryDigits = _query.replaceAll(RegExp(r'\D'), '');
                  final filtered = _query.isEmpty
                      ? assignable.toList()
                      : assignable
                          .where((d) =>
                              d.fullName.toLowerCase().contains(_query) ||
                              d.email.toLowerCase().contains(_query) ||
                              (queryDigits.isNotEmpty &&
                                  (d.phoneNumber ?? '')
                                      .replaceAll(RegExp(r'\D'), '')
                                      .contains(queryDigits)))
                          .toList();
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No matching approved drivers'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final driver = filtered[index];
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(driver.fullName),
                        subtitle: Text(
                          driver.phoneNumber == null
                              ? driver.email
                              : '${driver.email} · ${driver.phoneNumber}',
                        ),
                        onTap: () => Navigator.of(context).pop(driver),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
