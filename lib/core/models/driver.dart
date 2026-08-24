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

  String get fullName => '$forename $surname'.trim();
}

class DriverDocument {
  DriverDocument({
    required this.id,
    required this.type,
    required this.isVerified,
    this.uploadedAt,
    this.reviewStatus,
    this.rejectionReason,
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
      reviewStatus: json['reviewStatus'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  final String id;
  final String type;
  final bool isVerified;
  final DateTime? uploadedAt;
  final String? reviewStatus;
  final String? rejectionReason;
}
