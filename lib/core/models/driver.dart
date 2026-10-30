/// Approval workflow state. Confirmed via the backend's own generated API
/// reference: only these three values exist — there is no "suspended"
/// approval status.
enum DriverApprovalStatus {
  pending,
  approved,
  rejected,
  unknown;

  static DriverApprovalStatus fromApi(String? value) {
    switch (value) {
      case 'pending':
        return DriverApprovalStatus.pending;
      case 'approved':
        return DriverApprovalStatus.approved;
      case 'rejected':
        return DriverApprovalStatus.rejected;
      default:
        return DriverApprovalStatus.unknown;
    }
  }
}

/// Account state — separate concept from approval. Confirmed enum:
/// active | suspended | deletion_requested. A driver can be
/// approval_status=approved and status=suspended at the same time.
enum DriverAccountStatus {
  active,
  suspended,
  deletionRequested,
  unknown;

  static DriverAccountStatus fromApi(String? value) {
    switch (value) {
      case 'active':
        return DriverAccountStatus.active;
      case 'suspended':
        return DriverAccountStatus.suspended;
      case 'deletion_requested':
        return DriverAccountStatus.deletionRequested;
      default:
        return DriverAccountStatus.unknown;
    }
  }
}

class Driver {
  Driver({
    required this.id,
    required this.email,
    required this.forename,
    required this.surname,
    required this.phoneNumber,
    required this.approvalStatus,
    required this.accountStatus,
    this.avatarUrl,
    this.theme,
    this.phvDriverLicenceNumber,
    this.dateOfBirth,
    this.addressLine,
    this.postcode,
    this.drivingLicenceNumber,
    this.niNumber,
    this.callSign,
    this.vehicle,
    this.compliance,
    this.signedUpAt,
  });

  /// The user's own `GET /drivers/me` doesn't include an id field at all —
  /// per the backend's API reference, the driver's id is the JWT's `sub`
  /// claim instead. The admin's `GET /admin/drivers/:id` keys it as
  /// `user_id`, not `id`.
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      forename: json['forename'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      approvalStatus: DriverApprovalStatus.fromApi(json['approval_status'] as String?),
      accountStatus: DriverAccountStatus.fromApi(json['status'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      theme: json['theme_preference'] as String?,
      phvDriverLicenceNumber: json['phv_driver_licence_number'] as String?,
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? ''),
      addressLine: json['address_line'] as String?,
      postcode: json['postcode'] as String?,
      drivingLicenceNumber: json['driving_licence_number'] as String?,
      // Admin endpoint returns it in full (`ni_number`); the driver's own
      // `GET /drivers/me` only returns it masked.
      niNumber: (json['ni_number'] ?? json['ni_number_masked']) as String?,
      callSign: json['call_sign'] as String?,
      vehicle: Vehicle.activeFrom(json['vehicles'] as List?),
      compliance: json['compliance'] is Map<String, dynamic>
          ? DriverCompliance.fromJson(json['compliance'] as Map<String, dynamic>)
          : null,
      signedUpAt: DateTime.tryParse(json['signed_up_at'] as String? ?? ''),
    );
  }

  final String id;
  final String email;
  final String forename;
  final String surname;
  final String phoneNumber;
  final DriverApprovalStatus approvalStatus;
  final DriverAccountStatus accountStatus;
  final String? avatarUrl;
  final String? theme;

  /// TfL PHV driver licence number — the number on the driver's TfL badge.
  final String? phvDriverLicenceNumber;
  final DateTime? dateOfBirth;
  final String? addressLine;
  final String? postcode;

  /// DVLA driving licence number.
  final String? drivingLicenceNumber;
  final String? niNumber;

  /// Auto-assigned on approval ("TS001"); null until then.
  final String? callSign;
  final Vehicle? vehicle;
  final DriverCompliance? compliance;
  final DateTime? signedUpAt;

  String get fullName => '$forename $surname'.trim();
}

class Vehicle {
  Vehicle({
    required this.id,
    this.make,
    this.model,
    this.colour,
    this.registration,
    this.phvLicenceNumber,
    this.vehicleClass,
    this.ownedByDriver = true,
  });

  /// Vehicles come back as raw Prisma rows (camelCase) on both the driver's
  /// and admin's endpoints; a driver has at most one `active` vehicle.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'].toString(),
      make: json['make'] as String?,
      model: json['model'] as String?,
      colour: json['colour'] as String?,
      registration: json['vrm'] as String?,
      phvLicenceNumber: json['phvVehicleLicenceNumber'] as String?,
      vehicleClass: json['vehicleClass'] as String?,
      ownedByDriver: json['ownedByDriver'] as bool? ?? true,
    );
  }

  static Vehicle? activeFrom(List? vehicles) {
    final list = (vehicles ?? []).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    final active = list.where((v) => v['status'] == 'active');
    return Vehicle.fromJson(active.isNotEmpty ? active.first : list.first);
  }

  final String id;
  final String? make;
  final String? model;
  final String? colour;
  final String? registration;
  final String? phvLicenceNumber;
  final String? vehicleClass;
  final bool ownedByDriver;

  String get description => [colour, make, model].whereType<String>().where((s) => s.isNotEmpty).join(' ');
}

class ExpiringDocument {
  ExpiringDocument({required this.type, required this.expiryDate, this.daysLeft});

  factory ExpiringDocument.fromJson(Map<String, dynamic> json) => ExpiringDocument(
        type: json['type'] as String? ?? '',
        expiryDate: DateTime.tryParse(json['expiry_date'] as String? ?? '') ?? DateTime.now(),
        daysLeft: (json['days_left'] as num?)?.toInt(),
      );

  final String type;
  final DateTime expiryDate;
  final int? daysLeft;
}

/// Server-computed licensing compliance (see the backend's lib/compliance.ts):
/// what's missing, awaiting review, rejected, expired or expiring within 30
/// days. `compliant` is what gates approval.
class DriverCompliance {
  DriverCompliance({
    required this.compliant,
    required this.missingDocuments,
    required this.awaitingReview,
    required this.rejectedDocuments,
    required this.expired,
    required this.expiringSoon,
    required this.missingDetails,
  });

  factory DriverCompliance.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) => ((json[key] as List?) ?? []).map((e) => e.toString()).toList();
    List<ExpiringDocument> docs(String key) =>
        ((json[key] as List?) ?? []).cast<Map<String, dynamic>>().map(ExpiringDocument.fromJson).toList();
    return DriverCompliance(
      compliant: json['compliant'] as bool? ?? false,
      missingDocuments: strings('missing_documents'),
      awaitingReview: strings('awaiting_review'),
      rejectedDocuments: strings('rejected_documents'),
      expired: docs('expired'),
      expiringSoon: docs('expiring_soon'),
      missingDetails: strings('missing_details'),
    );
  }

  final bool compliant;
  final List<String> missingDocuments;
  final List<String> awaitingReview;
  final List<String> rejectedDocuments;
  final List<ExpiringDocument> expired;
  final List<ExpiringDocument> expiringSoon;
  final List<String> missingDetails;

  bool get hasExpired => expired.isNotEmpty;
  bool get hasExpiringSoon => expiringSoon.isNotEmpty;
}

class DriverDocument {
  DriverDocument({
    required this.id,
    required this.type,
    required this.isVerified,
    this.uploadedAt,
    this.reviewStatus,
    this.rejectionReason,
    this.expiryDate,
  });

  /// The backend returns this same data with two different casings
  /// depending on the endpoint: camelCase when embedded in
  /// `GET /admin/drivers/:id` (`documentType`, `verifiedByAdmin`), snake_case
  /// from `GET /drivers/me/documents` (`document_type`, `verified_by_admin`)
  /// — confirmed against the real API, not a guess. Both are checked here so
  /// this model works from either call site. `reviewStatus` (pending /
  /// verified / rejected) and `rejectionReason` were added alongside the new
  /// admin verify/reject + file-viewing endpoints — confirmed live.
  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'].toString(),
      type: (json['documentType'] ?? json['document_type'] ?? json['type'] ?? 'document')
          as String,
      isVerified: (json['verifiedByAdmin'] ?? json['verified_by_admin'] ?? false) as bool,
      uploadedAt: DateTime.tryParse(
        (json['uploadedAt'] ?? json['uploaded_at'] ?? '') as String? ?? '',
      ),
      reviewStatus: (json['reviewStatus'] ?? json['review_status']) as String?,
      rejectionReason: (json['rejectionReason'] ?? json['rejection_reason']) as String?,
      expiryDate: DateTime.tryParse((json['expiryDate'] ?? json['expiry_date'] ?? '') as String? ?? ''),
    );
  }

  final String id;
  final String type;
  final bool isVerified;
  final DateTime? uploadedAt;
  final String? reviewStatus;
  final String? rejectionReason;
  final DateTime? expiryDate;

  /// Whole days until expiry (negative once expired), null if it doesn't expire.
  int? get daysUntilExpiry {
    final e = expiryDate;
    if (e == null) return null;
    final today = DateTime.now();
    return DateTime(e.year, e.month, e.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  }
}
