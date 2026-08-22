import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/driver.dart';
import '../../../core/models/job.dart';
import '../../../core/network/dio_client.dart';
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

  Future<void> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path),
    });
    await _client.patchMultipart('/drivers/me', formData);
  }

  /// GET /drivers/me returns bank info as a single free-text string
  /// (`bank_account_details`), not structured fields — confirmed against
  /// the real API. The POST body's expected shape isn't documented or
  /// independently confirmed (untested to avoid overwriting the seeded demo
  /// account's bank details); this assumes symmetry with the GET field name.
  Future<void> submitBankDetails(String bankAccountDetails) async {
    await _client.post('/drivers/me/bank-details', data: {
      'bank_account_details': bankAccountDetails,
    });
  }

  Future<void> uploadDocument({required String documentType, required File file}) async {
    final formData = FormData.fromMap({
      'document_type': documentType,
      'file': await MultipartFile.fromFile(file.path),
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

  Future<void> releaseJob(String jobId, {required String reason}) =>
      _client.post('/jobs/$jobId/release', data: {'reason': reason});

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
