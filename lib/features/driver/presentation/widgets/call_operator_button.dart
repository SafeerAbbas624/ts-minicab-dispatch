import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/formatters.dart';

/// Drivers never get the passenger's number — anything about a booking
/// goes through the operating centre (TfL requirement).
class CallOperatorButton extends StatelessWidget {
  const CallOperatorButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => launchUrl(Uri.parse(operatorPhoneHref)),
        icon: const Icon(Icons.support_agent),
        label: const Text('Call operating centre ($operatorPhoneDisplay)'),
      ),
    );
  }
}
