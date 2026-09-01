import 'package:flutter/material.dart';

/// Public, no-login-required page describing how to delete a TS Minicab
/// account — this is the "Delete account URL" Google Play's Data Safety
/// form requires once an app declares it supports account creation. The
/// actual deletion still happens in-app (Settings > Request Account
/// Deletion, see DeleteAccountScreen), which Google's own policy allows —
/// a page doesn't have to perform the deletion itself, just clearly explain
/// how to do it, reachable without needing the app already installed.
class DeleteAccountInfoScreen extends StatelessWidget {
  const DeleteAccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delete Your Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How to delete your TS Minicab account', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text(
              'You can request deletion of your driver or admin account at any time, '
              'directly from the app — no need to contact support.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 20),
            Text('Steps', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Step(1, 'Open the TS Minicab app (or app.tsminicab.com in a browser) and log in.'),
            const _Step(2, 'Go to Settings.'),
            const _Step(3, 'Tap "Request Account Deletion".'),
            const _Step(4, 'Confirm on the screen that follows.'),
            const SizedBox(height: 24),
            Text('What happens next', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Bullet('Your login is disabled immediately — you will not be able to sign back in.'),
            const SizedBox(height: 16),
            Text('Data that is deleted', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            const _Bullet('Your name, email address, and phone number.'),
            const _Bullet('Your password / login credentials.'),
            const _Bullet('Your profile photo, if set.'),
            const _Bullet('Uploaded verification documents (licence, insurance, DBS, MOT, vehicle/driver photos, PCO badge), for drivers.'),
            const _Bullet('Bank details on file, for drivers.'),
            const _Bullet('These are removed shortly after your deletion request is processed.'),
            const SizedBox(height: 16),
            Text('Data that is kept, and for how long', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            const _Bullet('Job and trip records tied to your account (pickup/drop-off, fare, timestamps).'),
            const _Bullet('Payment records (what was paid, and when).'),
            const _Bullet('Admin action log entries referencing your account.'),
            const _Bullet(
              'These are retained indefinitely, for as long as required by law — UK tax, '
              'accounting, and private hire vehicle licensing rules all require these records '
              'to be kept even after an account is closed. There is no fixed deletion date for '
              'this category.',
            ),
            const SizedBox(height: 16),
            const _Bullet('This action cannot be undone.'),
            const SizedBox(height: 24),
            const Text(
              'If you can no longer log in and need your account and data deleted, '
              'contact admin@tsminicab.com from the email address on the account.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text('$number.', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
