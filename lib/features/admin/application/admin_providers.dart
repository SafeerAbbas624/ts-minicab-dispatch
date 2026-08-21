import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_driver_detail.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/models/job.dart';
import '../data/admin_repository.dart';

final adminDriversProvider =
    FutureProvider.autoDispose.family<List<AdminDriverSummary>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).fetchDrivers(status: status);
});

final adminDriverDetailProvider =
    FutureProvider.autoDispose.family<AdminDriverDetail, String>((ref, driverId) {
  return ref.watch(adminRepositoryProvider).fetchDriverDetail(driverId);
});

final adminJobsProvider =
    FutureProvider.autoDispose.family<List<Job>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).fetchJobs(status: status);
});

final adminAnalyticsProvider = FutureProvider.autoDispose<AdminAnalytics>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAnalytics();
});

final adminActionLogProvider = FutureProvider.autoDispose<List<ActionLogEntry>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchActionLog();
});
