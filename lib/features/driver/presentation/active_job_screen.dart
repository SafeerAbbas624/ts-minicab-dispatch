import 'package:flutter/material.dart';

import '../../../core/models/job.dart';
import 'widgets/active_job_view.dart';

/// Full-screen wrapper around [ActiveJobView] for the Jobs tab's compact
/// summary cards to push into — [ActiveJobView] renders as a `ListView`,
/// which needs a Scaffold-supplied bounded height (same reason
/// DriverDetailScreen wraps DriverDetailView the same way), not something
/// embedded inline alongside other active jobs on one combined screen.
class ActiveJobScreen extends StatelessWidget {
  const ActiveJobScreen({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Job')),
      body: ActiveJobView(job: job),
    );
  }
}
