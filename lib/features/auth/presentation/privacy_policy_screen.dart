import 'package:flutter/material.dart';

/// Placeholder copy — replace with the real TS Minicab privacy policy text
/// before store submission (App Store/Play both require the in-app copy to
/// match what's linked from the store listing).
const _placeholderPolicyText = '''
TS Minicab Privacy Policy

This app collects the personal and vehicle information you provide (name, contact details, licence, insurance, DBS and bank details) solely to operate the minicab dispatch service: verifying driver eligibility, assigning jobs, and processing payouts.

Data is retained as required for legal and audit purposes (including job and payment records) even after account deletion. You may request deletion of your account at any time from Settings — this disables login immediately; personal data is removed shortly after, while job and payment records are retained for legal/audit purposes.

We do not sell your data. Access is limited to TS Minicab administrators for dispatch and compliance purposes.
''';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(_placeholderPolicyText, style: TextStyle(height: 1.5)),
      ),
    );
  }
}
