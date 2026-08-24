// Decimal fields are plain JSON numbers as of the backend's normalization
// fix — this also tolerates a numeric string defensively.
double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class AdminDriverSummary {
  AdminDriverSummary({
    required this.id,
    required this.forename,
    required this.surname,
    required this.email,
    required this.status,
    required this.accountStatus,
    this.phoneNumber,
  });

  /// Confirmed against the backend's own generated API reference: the id
  /// field is `user_id`, not `id` (previously produced the literal string
  /// "null" here since `json['id']` doesn't exist, which is why tapping any
  /// driver 404'd — the request became `/admin/drivers/null`). Approval
  /// status is `approval_status` (pending/approved/rejected — no
  /// "suspended" value exists here); the plain `status` field is account
  /// state (active/suspended/deletion_requested), a separate concept.
  /// `phone_number` was added to this endpoint's response after a backend
  /// fix pass specifically so admin-side driver search could match on it.
  factory AdminDriverSummary.fromJson(Map<String, dynamic> json) {
    return AdminDriverSummary(
      id: json['user_id'].toString(),
      forename: json['forename'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['approval_status'] as String? ?? 'pending',
      accountStatus: json['status'] as String? ?? 'active',
      phoneNumber: json['phone_number'] as String?,
    );
  }

  final String id;
  final String forename;
  final String surname;
  final String email;
  final String status;
  final String accountStatus;
  final String? phoneNumber;

  String get fullName => '$forename $surname'.trim();
}

class DriverNote {
  DriverNote({required this.id, required this.text, required this.createdAt, this.authorName});

  /// Confirmed live against the real API: the field is `noteText`
  /// (camelCase, not `note_text`/`text`), `createdAt` is camelCase too, and
  /// the note's author is nested under `admin: {email, role}` (added after a
  /// backend bug-fix pass — previously there was no author field at all).
  factory DriverNote.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>?;
    return DriverNote(
      id: json['id'].toString(),
      text: json['noteText'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      authorName: admin?['email'] as String?,
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
    this.actionType,
    this.targetType,
    this.targetId,
    this.note,
  });

  /// The backend now resolves `description` (e.g. "demo.admin@... approved
  /// driver Pending Applicant") and `target_label` server-side — added after
  /// a bug-fix pass, previously the client had to build a description from
  /// `actionType`/`note` alone. Kept that as a fallback in case an older
  /// backend or a future entry type omits `description`. The raw fields are
  /// kept too (not just folded into the description) so a detail popup can
  /// show the exact target id and any note verbatim.
  factory ActionLogEntry.fromJson(Map<String, dynamic> json) {
    final admin = json['admin'] as Map<String, dynamic>?;
    final actionType = json['actionType'] as String?;
    final targetType = json['targetType'] as String?;
    final targetId = json['targetId']?.toString();
    final note = json['note'] as String?;
    final description = json['description'] as String?;
    if (description != null && description.isNotEmpty) {
      return ActionLogEntry(
        id: json['id'].toString(),
        description: description,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        actorName: admin?['email'] as String?,
        actionType: actionType,
        targetType: targetType,
        targetId: targetId,
        note: note,
      );
    }
    final humanized = actionType == null
        ? 'Unknown action'
        : actionType.replaceAll('_', ' ').replaceRange(0, 1, actionType[0].toUpperCase());
    return ActionLogEntry(
      id: json['id'].toString(),
      description: note == null || note.isEmpty ? humanized : '$humanized — $note',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      actorName: admin?['email'] as String?,
      actionType: actionType,
      targetType: targetType,
      targetId: targetId,
      note: note,
    );
  }

  final String id;
  final String description;
  final DateTime createdAt;
  final String? actionType;
  final String? targetType;
  final String? targetId;
  final String? note;
  final String? actorName;
}

/// GET /admin/jobs/:id/events — confirmed live. `actor_label` is already
/// resolved server-side (driver name, admin email, or "System (website)"),
/// same pattern as the action log's description — no client-side lookup
/// needed.
class JobEvent {
  JobEvent({
    required this.id,
    required this.eventType,
    required this.createdAt,
    this.actorLabel,
    this.note,
  });

  factory JobEvent.fromJson(Map<String, dynamic> json) {
    return JobEvent(
      id: json['id'].toString(),
      eventType: json['eventType'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      actorLabel: json['actor_label'] as String?,
      note: json['note'] as String?,
    );
  }

  final String id;
  final String eventType;
  final DateTime createdAt;
  final String? actorLabel;
  final String? note;
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
      totalRevenuePaid: _parseAmount(json['total_revenue_paid']),
      totalOutstandingUnpaid: _parseAmount(json['total_outstanding_unpaid']),
    );
  }

  final int totalJobs;
  final int completedJobs;
  final int openJobs;
  final int activeApprovedDrivers;
  final double totalRevenuePaid;
  final double totalOutstandingUnpaid;
}
