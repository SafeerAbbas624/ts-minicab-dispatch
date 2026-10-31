import 'dart:typed_data';

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

/// The driver's uploaded "Driver photo" document — the same photo
/// passengers see — used as their avatar. A verified photo wins over a
/// newer one still waiting for review; rejected photos are never shown.
/// Null when there's no photo or it can't be loaded.
final driverPhotoProvider = FutureProvider.autoDispose<Uint8List?>((ref) async {
  final docs = await ref.watch(driverDocumentsProvider.future);
  final photos = docs.where((d) => d.type == 'driver_photo' && d.reviewStatus != 'rejected').toList()
    ..sort((a, b) {
      final verified = (b.isVerified ? 1 : 0) - (a.isVerified ? 1 : 0);
      if (verified != 0) return verified;
      return (b.uploadedAt ?? DateTime(0)).compareTo(a.uploadedAt ?? DateTime(0));
    });
  if (photos.isEmpty) return null;
  try {
    return await ref.watch(driverRepositoryProvider).fetchDocumentFile(photos.first.id);
  } catch (_) {
    return null;
  }
});

final driverMeProvider = FutureProvider.autoDispose<Driver>((ref) {
  return ref.watch(driverRepositoryProvider).fetchMe();
});

/// Every status between accepting a job and completing it — matches the
/// backend's strict sequence (accepted → en_route → arrived →
/// passenger_on_board → completed, confirmed live 26 Aug).
const activeJobStatuses = {'accepted', 'en_route', 'arrived', 'passenger_on_board'};

/// All of the driver's current in-progress jobs, sorted by pickup time —
/// once the backend allows a driver to hold more than one non-overlapping
/// active job at a time (docs/BACKEND_REQUESTS.md item 1, reopened), this
/// can be more than one. `/jobs/mine` isn't documented as filterable by
/// status, so this filters client-side — flag to the backend session if a
/// dedicated "current jobs" endpoint would be cheaper.
final activeJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final jobs = await ref.watch(myJobsProvider.future);
  final active = jobs.where((job) => activeJobStatuses.contains(job.status)).toList();
  active.sort((a, b) => a.pickupDatetime.compareTo(b.pickupDatetime));
  return active;
});

/// Which bottom-nav tab DriverShell is showing: 0=Jobs, 1=History,
/// 2=Earnings, 3=Settings. Held as shared state (not local widget state) so
/// PendingApprovalView can jump straight to Settings > Documents from
/// wherever it's shown, the same pattern the admin dashboard's stat-card
/// shortcuts already use.
final driverTabIndexProvider = StateProvider<int>((ref) => 0);
