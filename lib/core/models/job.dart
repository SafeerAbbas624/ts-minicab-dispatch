/// Money fields (`fareAmount`, `amount`) are plain JSON numbers as of the
/// backend's Decimal-normalization fix — this also tolerates a numeric
/// string in case an older backend build is ever hit.
double _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class Job {
  Job({
    required this.id,
    required this.pickupDatetime,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.customerName,
    required this.customerContact,
    required this.fare,
    required this.status,
    this.source,
    this.notes,
    this.acceptedByDriverId,
    this.payment,
    this.vehicleClass,
  });

  /// Field names are camelCase on the wire (`pickupDatetime`, `pickupAddress`,
  /// `fareAmount`, `currentDriverId`, ...) — confirmed against the real API,
  /// not the snake_case originally assumed from the contract doc alone.
  /// There's no accepted-driver *name* anywhere in the job payload, only
  /// `currentDriverId` — admin screens that want a name have to resolve it
  /// separately (not wired up; contract has no such lookup documented).
  /// Admin-facing job responses (list/create/edit/approve/reassign) nest a
  /// `payment` object (or null) — that's how a paid completed job is told
  /// apart from an unpaid one, no separate lookup needed.
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'].toString(),
      pickupDatetime:
          DateTime.tryParse(json['pickupDatetime'] as String? ?? '') ?? DateTime.now(),
      pickupLocation: json['pickupAddress'] as String? ?? '',
      dropoffLocation: json['dropoffAddress'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerContact: json['customerContact'] as String? ?? '',
      fare: _parseAmount(json['fareAmount']),
      status: json['status'] as String? ?? 'open',
      source: json['source'] as String?,
      notes: json['notes'] as String?,
      acceptedByDriverId: json['currentDriverId']?.toString(),
      payment: json['payment'] != null ? Payment.fromJson(json['payment'] as Map<String, dynamic>) : null,
      vehicleClass: json['vehicleClassRequested'] as String?,
    );
  }

  final String id;
  final DateTime pickupDatetime;
  final String pickupLocation;
  final String dropoffLocation;
  final String customerName;
  final String customerContact;
  final double fare;
  final String status;
  final String? source;
  final String? notes;
  final String? vehicleClass;
  final String? acceptedByDriverId;
  final Payment? payment;
}

class PaymentDriverSummary {
  PaymentDriverSummary({required this.forename, required this.surname, this.licenceNumber});

  factory PaymentDriverSummary.fromJson(Map<String, dynamic> json) {
    return PaymentDriverSummary(
      forename: json['forename'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      licenceNumber: json['phvDriverLicenceNumber'] as String?,
    );
  }

  final String forename;
  final String surname;
  final String? licenceNumber;

  String get fullName => '$forename $surname'.trim();
}

class Payment {
  Payment({
    required this.id,
    required this.jobId,
    required this.amount,
    required this.isPaid,
    this.paidAt,
    this.transactionSlipPath,
    this.job,
    this.driver,
  });

  /// `GET /payments/mine` doesn't return a flat list — it returns
  /// `{unpaid: [...], paid: [...]}`, already bucketed, with each payment
  /// carrying a fully embedded `job` object. `paidStatus` is the real field
  /// name (not `status`). `GET /admin/payments` uses the same Payment shape
  /// but also nests a trimmed `driver` (forename/surname/licence number).
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      jobId: json['jobId'].toString(),
      amount: _parseAmount(json['amount']),
      isPaid: json['paidStatus'] == 'paid',
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
      transactionSlipPath: json['transactionSlipFilePath'] as String?,
      job: json['job'] != null ? Job.fromJson(json['job'] as Map<String, dynamic>) : null,
      driver: json['driver'] != null
          ? PaymentDriverSummary.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String jobId;
  final double amount;
  final bool isPaid;
  final DateTime? paidAt;
  final String? transactionSlipPath;
  final Job? job;
  final PaymentDriverSummary? driver;
}

/// `GET /payments/mine` response shape: pre-split into paid/unpaid buckets.
class PaymentsBucket {
  PaymentsBucket({required this.paid, required this.unpaid});

  factory PaymentsBucket.fromJson(Map<String, dynamic> json) {
    List<Payment> parseList(String key) =>
        ((json[key] as List?) ?? []).cast<Map<String, dynamic>>().map(Payment.fromJson).toList();
    return PaymentsBucket(paid: parseList('paid'), unpaid: parseList('unpaid'));
  }

  final List<Payment> paid;
  final List<Payment> unpaid;

  List<Payment> get all => [...paid, ...unpaid];
}
