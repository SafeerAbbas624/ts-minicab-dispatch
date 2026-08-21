import 'admin_models.dart';
import 'driver.dart';

class BankDetails {
  BankDetails({this.accountHolderName, this.sortCode, this.accountNumber});

  factory BankDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return BankDetails();
    return BankDetails(
      accountHolderName: json['account_holder_name'] as String?,
      sortCode: json['sort_code'] as String?,
      accountNumber: json['account_number'] as String?,
    );
  }

  final String? accountHolderName;
  final String? sortCode;
  final String? accountNumber;

  bool get hasAny => accountHolderName != null || sortCode != null || accountNumber != null;
}

/// The full driver record an admin sees: profile + documents + bank info +
/// notes. The contract doesn't document GET /admin/drivers/:id's exact shape,
/// so every nested section is parsed defensively (missing/renamed keys just
/// come back empty rather than crashing the detail screen).
class AdminDriverDetail {
  AdminDriverDetail({
    required this.driver,
    required this.documents,
    required this.notes,
    required this.bankDetails,
  });

  factory AdminDriverDetail.fromJson(Map<String, dynamic> json) {
    final documentsJson = (json['documents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final notesJson = (json['notes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return AdminDriverDetail(
      driver: Driver.fromJson(json),
      documents: documentsJson.map(DriverDocument.fromJson).toList(),
      notes: notesJson.map(DriverNote.fromJson).toList(),
      bankDetails: BankDetails.fromJson(json['bank_details'] as Map<String, dynamic>?),
    );
  }

  final Driver driver;
  final List<DriverDocument> documents;
  final List<DriverNote> notes;
  final BankDetails bankDetails;
}
