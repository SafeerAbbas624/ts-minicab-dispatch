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
    this.notes,
    this.acceptedByDriverId,
    this.acceptedByDriverName,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'].toString(),
      pickupDatetime:
          DateTime.tryParse(json['pickup_datetime'] as String? ?? '') ?? DateTime.now(),
      pickupLocation: json['pickup_location'] as String? ?? json['pickup'] as String? ?? '',
      dropoffLocation: json['dropoff_location'] as String? ?? json['dropoff'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerContact: json['customer_contact'] as String? ?? '',
      fare: (json['fare'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'open',
      notes: json['notes'] as String?,
      acceptedByDriverId: json['accepted_by_driver_id']?.toString(),
      acceptedByDriverName: json['accepted_by_driver_name'] as String?,
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
  final String? notes;
  final String? acceptedByDriverId;
  final String? acceptedByDriverName;
}

class Payment {
  Payment({
    required this.id,
    required this.jobId,
    required this.amount,
    required this.status,
    this.paidAt,
    this.transactionSlipUrl,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      jobId: json['job_id'].toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'unpaid',
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'] as String) : null,
      transactionSlipUrl: json['transaction_slip_url'] as String?,
    );
  }

  final String id;
  final String jobId;
  final double amount;
  final String status;
  final DateTime? paidAt;
  final String? transactionSlipUrl;

  bool get isPaid => status == 'paid';
}
