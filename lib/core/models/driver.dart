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

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'].toString(),
      email: json['email'] as String? ?? '',
      forename: json['forename'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      status: DriverApprovalStatus.fromApi(json['status'] as String?),
      avatarUrl: json['avatar_url'] as String?,
      theme: json['theme'] as String?,
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
    required this.status,
    this.fileUrl,
    this.uploadedAt,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) {
    return DriverDocument(
      id: json['id'].toString(),
      type: json['type'] as String? ?? json['document_type'] as String? ?? 'document',
      status: json['status'] as String? ?? 'pending',
      fileUrl: json['file_url'] as String?,
      uploadedAt:
          json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'] as String) : null,
    );
  }

  final String id;
  final String type;
  final String status;
  final String? fileUrl;
  final DateTime? uploadedAt;

  bool get isVerified => status == 'verified';
}
