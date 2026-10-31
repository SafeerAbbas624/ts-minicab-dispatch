import 'admin_models.dart';
import 'driver.dart';
import 'records_models.dart';

/// Confirmed against the real API: `bank_account_details` is a single
/// free-text string ("Sort code 12-34-56, Acc 12345678"), not a structured
/// object with separate account-holder/sort-code/account-number fields as
/// the contract doc's field list implied.
class BankDetails {
  BankDetails({this.raw});

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(raw: json['bank_account_details'] as String?);
  }

  final String? raw;

  bool get hasAny => raw != null && raw!.isNotEmpty;
}

/// The full driver record an admin sees: profile + documents + bank info +
/// notes, all flat on the same object (confirmed against the real API).
class AdminDriverDetail {
  AdminDriverDetail({
    required this.driver,
    required this.documents,
    required this.notes,
    required this.bankDetails,
    this.availability = const [],
    this.vehicles = const [],
    this.erasureDueAt,
  });

  factory AdminDriverDetail.fromJson(Map<String, dynamic> json) {
    final documentsJson = (json['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final notesJson = (json['notes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return AdminDriverDetail(
      driver: Driver.fromJson(json),
      documents: documentsJson.map(DriverDocument.fromJson).toList(),
      notes: notesJson.map(DriverNote.fromJson).toList(),
      bankDetails: BankDetails.fromJson(json),
      availability: ((json['availability'] as List?) ?? const []).cast<Map<String, dynamic>>().map(AvailabilityPeriod.fromJson).toList(),
      vehicles: ((json['vehicles'] as List?) ?? const []).cast<Map<String, dynamic>>().map(Vehicle.fromJson).toList(),
      erasureDueAt: DateTime.tryParse(json['erasure_due_at'] as String? ?? ''),
    );
  }

  final Driver driver;
  final List<DriverDocument> documents;
  final List<DriverNote> notes;
  final BankDetails bankDetails;

  /// Oldest first; the last one is open while the driver is available.
  final List<AvailabilityPeriod> availability;

  /// Current and former vehicles (a new registration starts a new record).
  final List<Vehicle> vehicles;

  /// Set once the driver has closed their account: the record is erased
  /// automatically on this date (12 months after leaving).
  final DateTime? erasureDueAt;
}
