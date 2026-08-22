import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/driver_repository.dart';

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sortCodeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sortCodeController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // The backend stores this as one free-text string (confirmed from
      // GET /admin/drivers/:id — e.g. "Sort code 12-34-56, Acc 12345678"),
      // not structured fields — kept as three inputs here for better UX and
      // combined into that format on submit.
      final combined = '${_nameController.text.trim()} — '
          'Sort code ${_sortCodeController.text.trim()}, '
          'Acc ${_accountNumberController.text.trim()}';
      await ref.read(driverRepositoryProvider).submitBankDetails(combined);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank details saved')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Account holder name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sortCodeController,
                  decoration: const InputDecoration(labelText: 'Sort code'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(labelText: 'Account number'),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
