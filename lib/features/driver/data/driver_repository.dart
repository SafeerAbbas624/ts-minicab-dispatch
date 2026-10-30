import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/driver.dart';
import '../../../core/models/job.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/providers/core_providers.dart';

class DriverRepository {
  DriverRepository(this._client);
  final ApiClient _client;

  Future<Driver> fetchMe() async {
    final res = await _client.get('/drivers/me');
    return Driver.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateMe({String? theme, String? avatarUrl, String? password}) async {
    final data = <String, dynamic>{};
    // GET /drivers/me returns this field as theme_preference, not theme —
    // confirmed against the real API.
    if (theme != null) data['theme_preference'] = theme;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (password != null) data['password'] = password;
    await _client.patch('/drivers/me', data: data);
  }

  /// Personal details for TfL licensing. Only keys present are changed;
  /// the NI number is encrypted server-side.
  Future<void> updateProfile(Map<String, dynamic> changes) =>
      _client.patch('/drivers/me/profile', data: changes);

  /// Creates or updates the driver's one active vehicle.
  Future<void> saveVehicle(Map<String, dynamic> vehicle) => _client.put('/drivers/me/vehicle', data: vehicle);

  /// Live location while a job is under way — feeds the passenger's
  /// tracking page. The backend ignores it outside en_route → on board.
  Future<void> sendLocation(
    String jobId, {
    required double lat,
    required double lng,
    double? heading,
    double? speed,
    double? accuracy,
  }) =>
      _client.post('/jobs/$jobId/location', data: {
        'lat': lat,
        'lng': lng,
        'heading': ?heading,
        'speed': ?speed,
        'accuracy': ?accuracy,
      });

  /// Confirmed via the backend's own API reference: bank details are stored
  /// as one encrypted free-text string under `bank_account_details`, and
  /// this is the exact request shape — no need to guess.
  Future<void> submitBankDetails(String bankAccountDetails) async {
    await _client.post('/drivers/me/bank-details', data: {
      'bank_account_details': bankAccountDetails,
    });
  }

  Future<void> uploadDocument({
    required String documentType,
    required File file,
    DateTime? expiryDate,
  }) async {
    final formData = FormData.fromMap({
      'document_type': documentType,
      'file': await MultipartFile.fromFile(file.path),
      // Date only — an expiry is a calendar day, not an instant.
      if (expiryDate != null) 'expiry_date': dateOnly(expiryDate),
    });
    await _client.postMultipart('/drivers/me/documents', formData);
  }

  Future<List<DriverDocument>> fetchDocuments() async {
    final res = await _client.get('/drivers/me/documents');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(DriverDocument.fromJson).toList();
  }

  Future<List<Job>> fetchOpenJobs() async {
    final res = await _client.get('/jobs/open');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    final jobs = list.map(Job.fromJson).toList();
    jobs.sort((a, b) => a.pickupDatetime.compareTo(b.pickupDatetime));
    return jobs;
  }

  Future<void> acceptJob(String jobId) => _client.post('/jobs/$jobId/accept');

  /// Confirmed live: the single entry point for a driver cancelling an
  /// accepted job. The backend itself decides what happens based on time to
  /// pickup — more than 2 hours out, the job is released immediately (no
  /// request row created); under 2 hours, a pending [CancellationRequest] is
  /// created instead and the job stays assigned until an admin approves or
  /// rejects it via `/admin/cancellation-requests/:id/approve|reject`.
  Future<void> requestCancellation(String jobId, {required String reason}) =>
      _client.post('/jobs/$jobId/request-cancellation', data: {'reason': reason});

  Future<void> updateJobStatus(String jobId, {required String status}) =>
      _client.post('/jobs/$jobId/status', data: {'status': status});

  Future<List<Job>> fetchMyJobs() async {
    final res = await _client.get('/jobs/mine');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Job.fromJson).toList();
  }

  /// GET /payments/mine returns `{unpaid: [...], paid: [...]}`, not a flat
  /// list — confirmed against the real API (the old flat-list assumption
  /// would throw a cast exception at runtime).
  Future<PaymentsBucket> fetchMyPayments() async {
    final res = await _client.get('/payments/mine');
    return PaymentsBucket.fromJson(res.data as Map<String, dynamic>);
  }
}

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository(ref.watch(apiClientProvider));
});
