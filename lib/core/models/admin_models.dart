class AdminDriverSummary {
  AdminDriverSummary({
    required this.id,
    required this.forename,
    required this.surname,
    required this.email,
    required this.status,
  });

  factory AdminDriverSummary.fromJson(Map<String, dynamic> json) {
    return AdminDriverSummary(
      id: json['id'].toString(),
      forename: json['forename'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
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
    required this.totalDrivers,
    required this.activeDrivers,
    required this.openJobs,
    required this.completedJobsThisWeek,
    required this.totalRevenueThisMonth,
    required this.outstandingPayments,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      totalDrivers: (json['total_drivers'] as num?)?.toInt() ?? 0,
      activeDrivers: (json['active_drivers'] as num?)?.toInt() ?? 0,
      openJobs: (json['open_jobs'] as num?)?.toInt() ?? 0,
      completedJobsThisWeek: (json['completed_jobs_this_week'] as num?)?.toInt() ?? 0,
      totalRevenueThisMonth: (json['total_revenue_this_month'] as num?)?.toDouble() ?? 0,
      outstandingPayments: (json['outstanding_payments'] as num?)?.toDouble() ?? 0,
    );
  }

  final int totalDrivers;
  final int activeDrivers;
  final int openJobs;
  final int completedJobsThisWeek;
  final double totalRevenueThisMonth;
  final double outstandingPayments;
}
