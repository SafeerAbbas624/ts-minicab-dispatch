import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/vehicle_classes.dart';
import '../../../core/models/driver.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../application/driver_providers.dart';
import '../data/driver_repository.dart';

/// Personal and vehicle details TfL requires for every driver. Shared by the
/// driver (their own details) and the admin panel (editing a driver), via
/// [onSaveProfile]/[onSaveVehicle].
class DriverDetailsForm extends StatefulWidget {
  const DriverDetailsForm({
    super.key,
    required this.driver,
    required this.onSaveProfile,
    required this.onSaveVehicle,
    this.niIsMasked = false,
  });

  final Driver driver;
  final Future<void> Function(Map<String, dynamic> changes) onSaveProfile;
  final Future<void> Function(Map<String, dynamic> vehicle) onSaveVehicle;

  /// The driver's own view only ever receives the NI number masked — the
  /// field then starts empty and is only sent if they type a new one.
  final bool niIsMasked;

  @override
  State<DriverDetailsForm> createState() => _DriverDetailsFormState();
}

class _DriverDetailsFormState extends State<DriverDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _forename = TextEditingController(text: widget.driver.forename);
  late final _surname = TextEditingController(text: widget.driver.surname);
  late final _phone = TextEditingController(text: widget.driver.phoneNumber);
  late final _address = TextEditingController(text: widget.driver.addressLine);
  late final _postcode = TextEditingController(text: widget.driver.postcode);
  late final _dvla = TextEditingController(text: widget.driver.drivingLicenceNumber);
  late final _badge = TextEditingController(text: widget.driver.phvDriverLicenceNumber);
  late final _ni = TextEditingController(text: widget.niIsMasked ? '' : widget.driver.niNumber);
  late DateTime? _dob = widget.driver.dateOfBirth;

  late final _make = TextEditingController(text: widget.driver.vehicle?.make);
  late final _model = TextEditingController(text: widget.driver.vehicle?.model);
  late final _colour = TextEditingController(text: widget.driver.vehicle?.colour);
  late final _vrm = TextEditingController(text: widget.driver.vehicle?.registration);
  late final _phv = TextEditingController(text: widget.driver.vehicle?.phvLicenceNumber);
  late String? _vehicleClass = widget.driver.vehicle?.vehicleClass;
  late bool _owned = widget.driver.vehicle?.ownedByDriver ?? true;
  late final _keeperName = TextEditingController(text: widget.driver.vehicle?.keeperName);
  late final _keeperAddress = TextEditingController(text: widget.driver.vehicle?.keeperAddress);

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_forename, _surname, _phone, _address, _postcode, _dvla, _badge, _ni, _make, _model, _colour, _vrm, _phv, _keeperName, _keeperAddress]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 35),
      firstDate: DateTime(now.year - 90),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add your date of birth')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSaveProfile({
        'forename': _forename.text.trim(),
        'surname': _surname.text.trim(),
        'phone_number': _phone.text.trim(),
        'date_of_birth': dateOnly(_dob!),
        'address_line': _address.text.trim(),
        'postcode': _postcode.text.trim(),
        'driving_licence_number': _dvla.text.trim(),
        'phv_driver_licence_number': _badge.text.trim(),
        if (_ni.text.trim().isNotEmpty) 'ni_number': _ni.text.trim(),
      });
      await widget.onSaveVehicle({
        'make': _make.text.trim(),
        'model': _model.text.trim(),
        'colour': _colour.text.trim(),
        'vrm': _vrm.text.trim(),
        'phv_vehicle_licence_number': _phv.text.trim(),
        'vehicle_class': ?_vehicleClass,
        'owned_by_driver': _owned,
        if (!_owned) 'keeper_name': _keeperName.text.trim(),
        if (!_owned) 'keeper_address': _keeperAddress.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details saved')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label,
      {String? hint, TextInputType? keyboard, bool caps = false, bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, hintText: hint),
        keyboardType: keyboard,
        textCapitalization: caps ? TextCapitalization.characters : TextCapitalization.words,
        validator: optional ? null : _required,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Personal details', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _field(_forename, 'First and middle names'),
          _field(_surname, 'Surname'),
          _field(_phone, 'Mobile number', keyboard: TextInputType.phone),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of birth', suffixIcon: Icon(Icons.calendar_today)),
                child: Text(_dob == null ? 'Select' : formatDate(_dob!)),
              ),
            ),
          ),
          _field(_address, 'Home address', hint: 'House number, street, town'),
          _field(_postcode, 'Postcode', caps: true),
          _field(_ni, 'National Insurance number',
              hint: widget.niIsMasked && widget.driver.niNumber != null ? 'On file (${widget.driver.niNumber}) — type to change' : 'QQ 12 34 56 C',
              caps: true,
              optional: widget.niIsMasked && widget.driver.niNumber != null),
          _field(_dvla, 'DVLA driving licence number', caps: true),
          _field(_badge, 'TfL PHV driver licence (badge) number', caps: true),
          const SizedBox(height: 12),
          Text('Vehicle', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _field(_make, 'Make', hint: 'e.g. Toyota'),
          _field(_model, 'Model', hint: 'e.g. Prius'),
          _field(_colour, 'Colour'),
          _field(_vrm, 'Registration plate', caps: true),
          _field(_phv, 'TfL PHV vehicle licence number', caps: true),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: vehicleClasses.any((c) => c.value == _vehicleClass) ? _vehicleClass : null,
              decoration: const InputDecoration(labelText: 'Vehicle class'),
              items: [for (final c in vehicleClasses) DropdownMenuItem(value: c.value, child: Text(c.value))],
              onChanged: (v) => setState(() => _vehicleClass = v),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I am the registered keeper of this vehicle'),
            subtitle: Text(_owned ? 'V5C in your name' : 'You will need to upload a permission letter from the owner'),
            value: _owned,
            onChanged: (v) => setState(() => _owned = v),
          ),
          if (!_owned) ...[
            const SizedBox(height: 8),
            _field(_keeperName, "Registered keeper's name", hint: 'As shown on the V5C'),
            _field(_keeperAddress, "Registered keeper's address", hint: 'Including postcode'),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save details'),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(driverMeProvider);
    final repo = ref.read(driverRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My details & vehicle')),
      body: meAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (driver) => DriverDetailsForm(
          driver: driver,
          niIsMasked: true,
          onSaveProfile: (changes) async {
            await repo.updateProfile(changes);
          },
          onSaveVehicle: (vehicle) async {
            await repo.saveVehicle(vehicle);
            ref.invalidate(driverMeProvider);
          },
        ),
      ),
    );
  }
}
