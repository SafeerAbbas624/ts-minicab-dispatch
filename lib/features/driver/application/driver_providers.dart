import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/driver.dart';
import '../../../core/models/job.dart';
import '../data/driver_repository.dart';

final openJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) {
  return ref.watch(driverRepositoryProvider).fetchOpenJobs();
});

final myJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) {
  return ref.watch(driverRepositoryProvider).fetchMyJobs();
});

final myPaymentsProvider = FutureProvider.autoDispose<PaymentsBucket>((ref) {
  return ref.watch(driverRepositoryProvider).fetchMyPayments();
});

final driverDocumentsProvider = FutureProvider.autoDispose<List<DriverDocument>>((ref) {
  return ref.watch(driverRepositoryProvider).fetchDocuments();
});

final driverMeProvider = FutureProvider.autoDispose<Driver>((ref) {
  return ref.watch(driverRepositoryProvider).fetchMe();
});

/// Every status between accepting a job and completing it — matches the
/// backend's strict sequence (accepted → en_route → arrived →
/// passenger_on_board → completed, confirmed live 26 Aug).
const activeJobStatuses = {'accepted', 'en_route', 'arrived', 'passenger_on_board'};

/// The driver's current in-progress job, if any. `/jobs/mine` isn't
/// documented as filterable by status, so this filters client-side — flag to
/// the backend session if a dedicated "current job" endpoint would be
/// cheaper.
final activeJobProvider = FutureProvider.autoDispose<Job?>((ref) async {
  final jobs = await ref.watch(myJobsProvider.future);
  for (final job in jobs) {
    if (activeJobStatuses.contains(job.status)) {
      return job;
    }
  }
  return null;
});

/// Which bottom-nav tab DriverShell is showing: 0=Jobs, 1=History,
/// 2=Earnings, 3=Settings. Held as shared state (not local widget state) so
/// PendingApprovalView can jump straight to Settings > Documents from
/// wherever it's shown, the same pattern the admin dashboard's stat-card
/// shortcuts already use.
final driverTabIndexProvider = StateProvider<int>((ref) => 0);
