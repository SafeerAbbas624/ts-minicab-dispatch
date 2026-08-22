import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

class JobPostingScreen extends ConsumerStatefulWidget {
  const JobPostingScreen({super.key});

  @override
  ConsumerState<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends ConsumerState<JobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerContactController = TextEditingController();
  final _fareController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _pickupDatetime;
  String _vehicleClass = _vehicleClasses.first;
  bool _isSaving = false;

  static const _vehicleClasses = ['Saloon', 'Estate', 'MPV', 'Executive'];

  @override
  void dispose() {
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _customerNameController.dispose();
    _customerContactController.dispose();
    _fareController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDatetime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupDatetime ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _pickupDatetime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  /// This screen is a static drawer tab inside AdminShell's IndexedStack, not
  /// a pushed route — there's nothing to pop back to. Popping here previously
  /// bubbled up to go_router's root navigator and popped /admin itself off
  /// its stack, crashing with "no pages left to show" (a black screen).
  void _resetForm() {
    _formKey.currentState!.reset();
    _pickupLocationController.clear();
    _dropoffLocationController.clear();
    _customerNameController.clear();
    _customerContactController.clear();
    _fareController.clear();
    _notesController.clear();
    setState(() {
      _pickupDatetime = null;
      _vehicleClass = _vehicleClasses.first;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDatetime == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pick a pickup date/time')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(adminRepositoryProvider).createJob(
            pickupDatetime: _pickupDatetime!,
            pickupLocation: _pickupLocationController.text.trim(),
            dropoffLocation: _dropoffLocationController.text.trim(),
            customerName: _customerNameController.text.trim(),
            customerContact: _customerContactController.text.trim(),
            fare: double.parse(_fareController.text.trim()),
            vehicleClass: _vehicleClass,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Job posted')));
      _resetForm();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _pickupDatetime == null
                        ? 'Pickup date/time'
                        : _pickupDatetime!.toString(),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateTime,
                ),
                TextFormField(
                  controller: _pickupLocationController,
                  decoration: const InputDecoration(labelText: 'Pickup location'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dropoffLocationController,
                  decoration: const InputDecoration(labelText: 'Dropoff location'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: 'Customer name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customerContactController,
                  decoration: const InputDecoration(labelText: 'Customer contact'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fareController,
                  decoration: const InputDecoration(labelText: 'Fare (£)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      (v == null || double.tryParse(v) == null) ? 'Enter a number' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleClass,
                  decoration: const InputDecoration(labelText: 'Vehicle class'),
                  items: _vehicleClasses
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _vehicleClass = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 3,
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
                      : const Text('Post Job'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
