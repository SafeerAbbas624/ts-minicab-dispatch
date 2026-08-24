import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/vehicle_classes.dart';
import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../data/admin_repository.dart';

class JobEditScreen extends ConsumerStatefulWidget {
  const JobEditScreen({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<JobEditScreen> createState() => _JobEditScreenState();
}

class _JobEditScreenState extends ConsumerState<JobEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pickupLocationController;
  late final TextEditingController _dropoffLocationController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerContactController;
  late final TextEditingController _fareController;
  late final TextEditingController _notesController;
  late DateTime _pickupDatetime;
  late String _vehicleClass;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _pickupLocationController = TextEditingController(text: job.pickupLocation);
    _dropoffLocationController = TextEditingController(text: job.dropoffLocation);
    _customerNameController = TextEditingController(text: job.customerName);
    _customerContactController = TextEditingController(text: job.customerContact);
    _fareController = TextEditingController(text: job.fare.toString());
    _notesController = TextEditingController(text: job.notes ?? '');
    _pickupDatetime = job.pickupDatetime;
    // The job's own vehicleClass may be a value from before the fleet list
    // changed — fall back to the first option rather than a dropdown with
    // no matching item selected.
    _vehicleClass = vehicleClasses.any((c) => c.value == job.vehicleClass)
        ? job.vehicleClass!
        : vehicleClasses.first.value;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDatetime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupDatetime),
    );
    if (time == null) return;
    setState(() {
      _pickupDatetime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // PATCH /admin/jobs/:id uses the same snake_case body shape as create
      // (confirmed via the backend's API reference) — different casing than
      // the camelCase GET response, intentionally.
      await ref.read(adminRepositoryProvider).updateJob(widget.job.id, {
        'pickup_datetime': _pickupDatetime.toUtc().toIso8601String(),
        'pickup_address': _pickupLocationController.text.trim(),
        'dropoff_address': _dropoffLocationController.text.trim(),
        'customer_name': _customerNameController.text.trim(),
        'customer_contact': _customerContactController.text.trim(),
        'fare_amount': double.parse(_fareController.text.trim()),
        'vehicle_class_requested': _vehicleClass,
        'notes': _notesController.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      appBar: AppBar(title: const Text('Edit Job')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Pickup date/time'),
                  subtitle: Text(_pickupDatetime.toString()),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 16),
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
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Vehicle class'),
                  items: vehicleClasses
                      .map((c) => DropdownMenuItem(
                            value: c.value,
                            child: Text('${c.value} — ${c.tagline} (${c.subtitle})'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _vehicleClass = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
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
