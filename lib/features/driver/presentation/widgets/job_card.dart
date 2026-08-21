import 'package:flutter/material.dart';

import '../../../../core/models/job.dart';
import '../../../../core/utils/formatters.dart';

class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, this.onTap, this.trailing});

  final Job job;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(formatDateTime(job.pickupDatetime)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${job.pickupLocation} → ${job.dropoffLocation}'),
            Text(job.customerName),
          ],
        ),
        isThreeLine: true,
        trailing: trailing ?? Text(formatCurrency(job.fare)),
      ),
    );
  }
}
