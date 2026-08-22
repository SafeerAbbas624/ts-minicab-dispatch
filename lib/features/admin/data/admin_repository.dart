import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_driver_detail.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/models/job.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';

class AdminRepository {
  AdminRepository(this._client);
  final ApiClient _client;

  // Drivers

  Future<List<AdminDriverSummary>> fetchDrivers({String? status}) async {
    final res = await _client.get('/admin/drivers', query: status != null ? {'status': status} : null);
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(AdminDriverSummary.fromJson).toList();
  }

  Future<AdminDriverDetail> fetchDriverDetail(String driverId) async {
    final res = await _client.get('/admin/drivers/$driverId');
    return AdminDriverDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> approveDriver(String driverId) => _client.post('/admin/drivers/$driverId/approve');

  Future<void> rejectDriver(String driverId) => _client.post('/admin/drivers/$driverId/reject');

  Future<void> suspendDriver(String driverId) => _client.post('/admin/drivers/$driverId/suspend');

  Future<void> deleteDriver(String driverId) => _client.delete('/admin/drivers/$driverId');

  Future<void> addDriverNote(String driverId, String noteText) =>
      _client.post('/admin/drivers/$driverId/notes', data: {'note_text': noteText});

  // Admins

  Future<void> createAdmin({required String email, required String password}) =>
      _client.post('/admin/admins', data: {'email': email, 'password': password});

  Future<void> deleteAdmin(String adminId) => _client.delete('/admin/admins/$adminId');

  // Jobs

  /// Confirmed via the backend's own generated API reference: unlike GET
  /// responses (camelCase, raw Prisma rows), the create/update request body
  /// is snake_case — an intentional asymmetry, not a typo. `vehicle_class`
  /// and `fare` are technically optional per that reference, but the UI
  /// still requires them since every real job has both.
  Future<void> createJob({
    required DateTime pickupDatetime,
    required String pickupLocation,
    required String dropoffLocation,
    required String customerName,
    required String customerContact,
    required double fare,
    required String vehicleClass,
    String? notes,
  }) {
    return _client.post('/admin/jobs', data: {
      // .toUtc() so this serializes with a Z suffix, matching the backend's
      // own timestamps (e.g. "2026-08-25T15:00:00.000Z") — date/time pickers
      // produce local time, which toIso8601String() alone would send without
      // any timezone marker.
      'pickup_datetime': pickupDatetime.toUtc().toIso8601String(),
      'pickup_address': pickupLocation,
      'dropoff_address': dropoffLocation,
      'customer_name': customerName,
      'customer_contact': customerContact,
      'fare_amount': fare,
      'vehicle_class_requested': vehicleClass,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }

  Future<List<Job>> fetchJobs({String? status}) async {
    final res = await _client.get('/admin/jobs', query: status != null ? {'status': status} : null);
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Job.fromJson).toList();
  }

  Future<void> updateJob(String jobId, Map<String, dynamic> changes) =>
      _client.patch('/admin/jobs/$jobId', data: changes);

  Future<void> approveJob(String jobId) => _client.post('/admin/jobs/$jobId/approve');

  Future<void> cancelJob(String jobId, {required String reason}) =>
      _client.post('/admin/jobs/$jobId/cancel', data: {'reason': reason});

  /// Confirmed: takes no body — it just unassigns the current driver
  /// (accepted → open, clears currentDriverId), it doesn't target a specific
  /// replacement driver despite the name.
  Future<void> reassignJob(String jobId) => _client.post('/admin/jobs/$jobId/reassign');

  // Payments

  Future<void> markPaid(String jobId, {File? transactionSlip}) async {
    final formData = FormData.fromMap({
      if (transactionSlip != null)
        'transaction_slip': await MultipartFile.fromFile(transactionSlip.path),
    });
    await _client.postMultipart('/admin/payments/$jobId/mark-paid', formData);
  }

  /// Dedicated payments-first view — each row nests the full job and a
  /// trimmed driver. `status` is 'paid' or 'unpaid'; omit for all.
  Future<List<Payment>> fetchAdminPayments({String? status}) async {
    final res =
        await _client.get('/admin/payments', query: status != null ? {'status': status} : null);
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Payment.fromJson).toList();
  }

  // Analytics / TfL / action log

  Future<AdminAnalytics> fetchAnalytics() async {
    final res = await _client.get('/admin/analytics');
    return AdminAnalytics.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchTflExport({required DateTime weekStart}) async {
    final res = await _client.get(
      '/admin/tfl-export',
      query: {'week_start': _dateOnly(weekStart)},
    );
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<int>> fetchTflExportCsv({required DateTime weekStart}) async {
    final res = await _client.getBytes(
      '/admin/tfl-export/csv',
      query: {'week_start': _dateOnly(weekStart)},
    );
    return res.data ?? [];
  }

  Future<List<ActionLogEntry>> fetchActionLog() async {
    final res = await _client.get('/admin/action-log');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ActionLogEntry.fromJson).toList();
  }

  String _dateOnly(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});
