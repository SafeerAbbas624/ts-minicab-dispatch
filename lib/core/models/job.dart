/// Money fields (`fareAmount`, `amount`) come back as JSON strings ("65"),
/// not numbers — confirmed against the real API. Handles a numeric value too
/// in case that ever changes.
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
  });

  /// Field names are camelCase on the wire (`pickupDatetime`, `pickupAddress`,
  /// `fareAmount`, `currentDriverId`, ...) — confirmed against the real API,
  /// not the snake_case originally assumed from the contract doc alone.
  /// There's no accepted-driver *name* anywhere in the job payload, only
  /// `currentDriverId` — admin screens that want a name have to resolve it
  /// separately (not wired up; contract has no such lookup documented).
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
  final String? acceptedByDriverId;
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
  });

  /// `GET /payments/mine` doesn't return a flat list — it returns
  /// `{unpaid: [...], paid: [...]}`, already bucketed, with each payment
  /// carrying a fully embedded `job` object. Confirmed against the real API;
  /// nothing in the contract doc hinted at this shape. `paidStatus` is the
  /// real field name (not `status`), and `amount` is a JSON string like
  /// `fareAmount`.
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      jobId: json['jobId'].toString(),
      amount: _parseAmount(json['amount']),
      isPaid: json['paidStatus'] == 'paid',
      paidAt: DateTime.tryParse(json['paidAt'] as String? ?? ''),
      transactionSlipPath: json['transactionSlipFilePath'] as String?,
      job: json['job'] != null ? Job.fromJson(json['job'] as Map<String, dynamic>) : null,
    );
  }

  final String id;
  final String jobId;
  final double amount;
  final bool isPaid;
  final DateTime? paidAt;
  final String? transactionSlipPath;
  final Job? job;
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
