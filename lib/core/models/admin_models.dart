class AdminDriverSummary {
  AdminDriverSummary({
    required this.id,
    required this.forename,
    required this.surname,
    required this.email,
    required this.status,
  });

  /// Confirmed against the real API: the id field is `user_id`, not `id`
  /// (previously produced the literal string "null" here since `json['id']`
  /// doesn't exist, which is why tapping any driver 404'd — the request
  /// became `/admin/drivers/null`). Approval status is `approval_status`;
  /// the plain `status` field is account active/inactive, unrelated.
  factory AdminDriverSummary.fromJson(Map<String, dynamic> json) {
    return AdminDriverSummary(
      id: json['user_id'].toString(),
      forename: json['forename'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['approval_status'] as String? ?? 'pending',
    );
  }

  final String id;
  final String forename;
  final String surname;
  final String email;
  final String status;

  String get fullName => '$forename $surname'.trim();
}

class DriverNote {
  DriverNote({required this.id, required this.text, required this.createdAt, this.authorName});

  factory DriverNote.fromJson(Map<String, dynamic> json) {
    return DriverNote(
      id: json['id'].toString(),
      text: json['note_text'] as String? ?? json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      authorName: json['author_name'] as String?,
    );
  }

  final String id;
  final String text;
  final DateTime createdAt;
  final String? authorName;
}

class ActionLogEntry {
  ActionLogEntry({
    required this.id,
    required this.description,
    required this.createdAt,
    this.actorName,
  });

  factory ActionLogEntry.fromJson(Map<String, dynamic> json) {
    return ActionLogEntry(
      id: json['id'].toString(),
      description:
          json['description'] as String? ?? json['action'] as String? ?? 'Unknown action',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      actorName: json['actor_name'] as String?,
    );
  }

  final String id;
  final String description;
  final DateTime createdAt;
  final String? actorName;
}

class AdminAnalytics {
  AdminAnalytics({
    required this.totalJobs,
    required this.completedJobs,
    required this.openJobs,
    required this.activeApprovedDrivers,
    required this.totalRevenuePaid,
    required this.totalOutstandingUnpaid,
  });

  /// Confirmed against the real API — the field set is smaller and named
  /// differently than the contract implied (no total-driver count, no
  /// week/month breakdowns, just running totals).
  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      totalJobs: (json['total_jobs'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      openJobs: (json['open_jobs'] as num?)?.toInt() ?? 0,
      activeApprovedDrivers: (json['active_approved_drivers'] as num?)?.toInt() ?? 0,
      totalRevenuePaid: (json['total_revenue_paid'] as num?)?.toDouble() ?? 0,
      totalOutstandingUnpaid: (json['total_outstanding_unpaid'] as num?)?.toDouble() ?? 0,
    );
  }

  final int totalJobs;
  final int completedJobs;
  final int openJobs;
  final int activeApprovedDrivers;
  final double totalRevenuePaid;
  final double totalOutstandingUnpaid;
}
