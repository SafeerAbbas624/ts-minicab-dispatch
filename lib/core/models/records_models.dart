/// TfL operator records beyond bookings: complaints (reg 14), lost property
/// (reg 15), the booking & dispatch staff register, and each driver's
/// availability history. All snake_case, built by the backend's records
/// routes.
library;

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

/// One period a driver was available to carry out bookings — "date first
/// available", "date of leaving" and restarts on TfL's driver record.
class AvailabilityPeriod {
  AvailabilityPeriod({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.endReason,
    this.endReasonLabel,
    this.endNote,
    this.phv105DueAt,
    this.reportedToTflAt,
  });

  factory AvailabilityPeriod.fromJson(Map<String, dynamic> json) => AvailabilityPeriod(
        id: json['id'].toString(),
        startedAt: _date(json['started_at']) ?? DateTime.now(),
        endedAt: _date(json['ended_at']),
        endReason: json['end_reason'] as String?,
        endReasonLabel: json['end_reason_label'] as String?,
        endNote: json['end_note'] as String?,
        phv105DueAt: _date(json['phv105_due_at']),
        reportedToTflAt: _date(json['reported_to_tfl_at']),
      );

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? endReason;
  final String? endReasonLabel;
  final String? endNote;
  final DateTime? phv105DueAt;
  final DateTime? reportedToTflAt;

  bool get isCurrent => endedAt == null;
  bool get needsTflReport => phv105DueAt != null && reportedToTflAt == null;
}

/// Why a driver stopped being available (backend `LeaveReason`).
const leaveReasons = <String, String>{
  'resigned': 'Left / resigned',
  'conduct': 'Conduct — must be reported to TfL (PHV/105)',
  'documents': 'Documents expired or not valid',
  'other': 'Other',
};

class Complaint {
  Complaint({
    required this.id,
    required this.ref,
    required this.kind,
    required this.status,
    required this.source,
    required this.receivedAt,
    required this.complainantName,
    required this.details,
    this.handledBy,
    this.bookingRef,
    this.bookingAt,
    this.driverName,
    this.vehicleReg,
    this.address,
    this.phone,
    this.email,
    this.investigation,
    this.result,
    this.closedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'].toString(),
        ref: json['ref'] as String? ?? '',
        kind: json['kind'] as String? ?? 'complaint',
        status: json['status'] as String? ?? 'open',
        source: json['source'] as String? ?? 'admin',
        receivedAt: _date(json['received_at']) ?? DateTime.now(),
        complainantName: json['complainant_name'] as String? ?? '',
        details: json['details'] as String? ?? '',
        handledBy: json['handled_by'] as String?,
        bookingRef: json['booking_ref'] as String?,
        bookingAt: _date(json['booking_at']),
        driverName: json['driver_name'] as String?,
        vehicleReg: json['vehicle_reg'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        investigation: json['investigation'] as String?,
        result: json['result'] as String?,
        closedAt: _date(json['closed_at']),
      );

  final String id;
  final String ref;
  final String kind;
  final String status;
  final String source;
  final DateTime receivedAt;
  final String complainantName;
  final String details;
  final String? handledBy;
  final String? bookingRef;
  final DateTime? bookingAt;
  final String? driverName;
  final String? vehicleReg;
  final String? address;
  final String? phone;
  final String? email;
  final String? investigation;
  final String? result;
  final DateTime? closedAt;

  bool get isOpen => status == 'open';
  bool get isCompliment => kind == 'compliment';
}

class LostPropertyItem {
  LostPropertyItem({
    required this.id,
    required this.ref,
    required this.kind,
    required this.status,
    required this.source,
    required this.receivedAt,
    required this.description,
    this.handedInBy,
    this.handledBy,
    this.bookingRef,
    this.bookingAt,
    this.lostAt,
    this.place,
    this.vehicleReg,
    this.customerName,
    this.address,
    this.phone,
    this.email,
    this.actionsTaken,
    this.result,
    this.disposal,
    this.closedAt,
  });

  factory LostPropertyItem.fromJson(Map<String, dynamic> json) => LostPropertyItem(
        id: json['id'].toString(),
        ref: json['ref'] as String? ?? '',
        kind: json['kind'] as String? ?? 'found',
        status: json['status'] as String? ?? 'open',
        source: json['source'] as String? ?? 'admin',
        receivedAt: _date(json['received_at']) ?? DateTime.now(),
        description: json['description'] as String? ?? '',
        handedInBy: json['handed_in_by'] as String?,
        handledBy: json['handled_by'] as String?,
        bookingRef: json['booking_ref'] as String?,
        bookingAt: _date(json['booking_at']),
        lostAt: _date(json['lost_at']),
        place: json['place'] as String?,
        vehicleReg: json['vehicle_reg'] as String?,
        customerName: json['customer_name'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        actionsTaken: json['actions_taken'] as String?,
        result: json['result'] as String?,
        disposal: json['disposal'] as String?,
        closedAt: _date(json['closed_at']),
      );

  final String id;
  final String ref;
  final String kind;
  final String status;
  final String source;
  final DateTime receivedAt;
  final String description;
  final String? handedInBy;
  final String? handledBy;
  final String? bookingRef;
  final DateTime? bookingAt;
  final DateTime? lostAt;
  final String? place;
  final String? vehicleReg;
  final String? customerName;
  final String? address;
  final String? phone;
  final String? email;
  final String? actionsTaken;
  final String? result;
  final String? disposal;
  final DateTime? closedAt;

  bool get isOpen => status == 'open';
  bool get isFound => kind == 'found';
}

/// One person on the register of booking & dispatch staff (TfL condition
/// since 1 July 2024).
class StaffRegisterEntry {
  StaffRegisterEntry({
    required this.id,
    required this.email,
    required this.status,
    required this.missing,
    this.displayName,
    this.fullName,
    this.dateOfBirth,
    this.dbsCertificateNumber,
    this.dbsIssueDate,
    this.dbsSeenDate,
    this.enteredAt,
    this.ceasedAt,
  });

  factory StaffRegisterEntry.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? user}) {
    final r = json;
    return StaffRegisterEntry(
      id: (user ?? json)['id'].toString(),
      email: (user ?? json)['email'] as String? ?? '',
      status: (user ?? json)['status'] as String? ?? 'active',
      displayName: (user ?? json)['display_name'] as String?,
      missing: (r['missing'] as List?)?.cast<String>() ?? const [],
      fullName: r['full_name'] as String?,
      dateOfBirth: _date(r['date_of_birth']),
      dbsCertificateNumber: r['dbs_certificate_number'] as String?,
      dbsIssueDate: _date(r['dbs_issue_date']),
      dbsSeenDate: _date(r['dbs_seen_date']),
      enteredAt: _date(r['entered_at']),
      ceasedAt: _date(r['ceased_at']),
    );
  }

  final String id;
  final String email;
  final String status;
  final String? displayName;
  final List<String> missing;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? dbsCertificateNumber;
  final DateTime? dbsIssueDate;
  final DateTime? dbsSeenDate;
  final DateTime? enteredAt;
  final DateTime? ceasedAt;

  bool get isRemoved => ceasedAt != null || status != 'active';
  String get name => fullName?.isNotEmpty == true ? fullName! : (displayName ?? email);
}

class ComplianceSummary {
  ComplianceSummary({
    required this.openComplaints,
    required this.openLostProperty,
    required this.phv105Due,
    required this.staffRegisterIncomplete,
  });

  factory ComplianceSummary.fromJson(Map<String, dynamic> json) => ComplianceSummary(
        openComplaints: json['open_complaints'] as int? ?? 0,
        openLostProperty: json['open_lost_property'] as int? ?? 0,
        phv105Due: (json['phv105_due'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map((p) => (driverId: p['driver_id'].toString(), driverName: p['driver_name'] as String? ?? '', dueAt: _date(p['due_at'])))
            .toList(),
        staffRegisterIncomplete:
            (json['staff_register_incomplete'] as List? ?? const []).cast<Map<String, dynamic>>().map((s) => s['name'] as String? ?? '').toList(),
      );

  final int openComplaints;
  final int openLostProperty;
  final List<({String driverId, String driverName, DateTime? dueAt})> phv105Due;
  final List<String> staffRegisterIncomplete;

  bool get isClear => openComplaints == 0 && openLostProperty == 0 && phv105Due.isEmpty && staffRegisterIncomplete.isEmpty;
}
