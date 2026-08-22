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

  /// GET responses for jobs use camelCase (pickupDatetime, pickupAddress,
  /// fareAmount, ...) and every sample job carries a vehicleClassRequested
  /// value — confirmed against the real API. The POST body's exact expected
  /// shape isn't independently confirmed, but matching the GET field names
  /// is the best-evidenced guess (replacing the original snake_case guess,
  /// which is now known wrong for at least the response side).
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
      'pickupDatetime': pickupDatetime.toIso8601String(),
      'pickupAddress': pickupLocation,
      'dropoffAddress': dropoffLocation,
      'customerName': customerName,
      'customerContact': customerContact,
      'fareAmount': fare,
      'vehicleClassRequested': vehicleClass,
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

  Future<void> reassignJob(String jobId, {String? driverId}) => _client.post(
        '/admin/jobs/$jobId/reassign',
        data: driverId != null ? {'driver_id': driverId} : null,
      );

  // Payments

  Future<void> markPaid(String jobId, {File? transactionSlip}) async {
    final formData = FormData.fromMap({
      if (transactionSlip != null)
        'transaction_slip': await MultipartFile.fromFile(transactionSlip.path),
    });
    await _client.postMultipart('/admin/payments/$jobId/mark-paid', formData);
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
