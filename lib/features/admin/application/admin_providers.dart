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

final adminPaymentsProvider =
    FutureProvider.autoDispose.family<List<Payment>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).fetchAdminPayments(status: status);
});

final adminAnalyticsProvider = FutureProvider.autoDispose<AdminAnalytics>((ref) {
  return ref.watch(adminRepositoryProvider).fetchAnalytics();
});

final adminActionLogProvider = FutureProvider.autoDispose<List<ActionLogEntry>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchActionLog();
});

/// Which top-level drawer destination is showing. Index order matches
/// AdminShell's screen list: Dashboard, Jobs, Drivers, Payments, TfL Export,
/// Action Logs, Settings. Held as shared state (not local widget state) so
/// Dashboard's stat cards can jump straight to a tab — and a sub-tab inside
/// it — from outside AdminShell's own widget tree.
final adminTabIndexProvider = StateProvider<int>((ref) => 0);

/// Sub-tab within the Jobs mega-tab: 0=Post a Job, 1=Website Jobs,
/// 2=Active Jobs, 3=Completed Jobs.
final jobsSubTabIndexProvider = StateProvider<int>((ref) => 0);

/// Sub-tab within Drivers: 0=All, 1=Pending, 2=Approved, 3=Rejected.
/// Defaults to Pending (1), matching the queue-first behavior the screen
/// had before the filter moved from top chips to a bottom nav bar.
final driversSubTabIndexProvider = StateProvider<int>((ref) => 1);

/// Sub-tab within Payments: 0=Unpaid, 1=Paid.
final paymentsSubTabIndexProvider = StateProvider<int>((ref) => 0);
