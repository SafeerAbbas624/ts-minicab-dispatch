enum DriverApprovalStatus {
  pending,
  approved,
  rejected,
  suspended,
  unknown;

  static DriverApprovalStatus fromApi(String? value) {
    switch (value) {
      case 'pending':
        return DriverApprovalStatus.pending;
      case 'approved':
        return DriverApprovalStatus.approved;
      case 'rejected':
        return DriverApprovalStatus.rejected;
      case 'suspended':
        return DriverApprovalStatus.suspended;
      default:
        return DriverApprovalStatus.unknown;
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
    required this.status,
    this.avatarUrl,
    this.theme,
  });

  /// The user's own `GET /drivers/me` doesn't include an id field at all
  /// (confirmed against the real API); the admin's `GET /admin/drivers/:id`
  /// keys it as `user_id`, not `id`. Approval status lives under
  /// `approval_status` — the plain `status` field is account active/inactive,
  /// a different concept entirely (also confirmed against the real API).
  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: (json['user_id'] ?? json['id'] ?? '').toString(),
      email: json['email'] as String? ?? '',
      forename: json['forename'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      status: DriverApprovalStatus.fromApi(json['approval_status'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      theme: json['theme_preference'] as String?,
    );
  }

  final String id;
  final String email;
  final String forename;
  final String surname;
  final String phoneNumber;
  final DriverApprovalStatus status;
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
  });

  /// The backend returns this same data with two different casings
  /// depending on the endpoint: camelCase when embedded in
  /// `GET /admin/drivers/:id` (`documentType`, `verifiedByAdmin`), snake_case
  /// from `GET /drivers/me/documents` (`document_type`, `verified_by_admin`)
  /// — confirmed against the real API, not a guess. Both are checked here so
  /// this model works from either call site. There's no file URL in either
  /// shape (only a server filesystem path, `filePath`/`file_path`, not
  /// publicly fetchable) — flagged as an open gap, not something to paper
  /// over with a fake URL.
  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'].toString(),
      type: (json['documentType'] ?? json['document_type'] ?? json['type'] ?? 'document')
          as String,
      isVerified: (json['verifiedByAdmin'] ?? json['verified_by_admin'] ?? false) as bool,
      uploadedAt: DateTime.tryParse(
        (json['uploadedAt'] ?? json['uploaded_at'] ?? '') as String? ?? '',
      ),
    );
  }

  final String id;
  final String type;
  final bool isVerified;
  final DateTime? uploadedAt;
}
