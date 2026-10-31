import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../application/driver_providers.dart';
import 'widgets/active_job_view.dart';

/// Full-screen wrapper around [ActiveJobView] for the Jobs tab's compact
/// summary cards to push into — [ActiveJobView] renders as a `ListView`,
/// which needs a Scaffold-supplied bounded height (same reason
/// DriverDetailScreen wraps DriverDetailView the same way), not something
/// embedded inline alongside other active jobs on one combined screen.
///
/// [job] is only the snapshot the card was tapped with: the screen follows
/// the live copy in [myJobsProvider], so each step (Start job → Arrived →
/// On board → Completed) shows as soon as it's saved.
class ActiveJobScreen extends ConsumerWidget {
  const ActiveJobScreen({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(myJobsProvider).valueOrNull;
    final live = jobs?.where((j) => j.id == job.id).firstOrNull ?? job;
    return Scaffold(
      appBar: AppBar(title: const Text('Active Job')),
      body: ActiveJobView(job: live),
    );
  }
}
