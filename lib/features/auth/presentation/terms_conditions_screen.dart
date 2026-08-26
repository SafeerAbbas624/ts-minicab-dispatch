import 'package:flutter/material.dart';

/// Describes how this app's own dispatch, job-acceptance/cancellation, and
/// payment features actually work (matches the real backend behavior: a
/// driver may hold one active job at a time, cancellations within 2 hours
/// of pickup go to admin review and may carry a penalty, payouts are bank
/// transfers arranged by an administrator). Kept to what the app itself
/// does — not a substitute for a solicitor's sign-off before real-world
/// publication, but accurate to the system as built so it can't contradict
/// what App Store/Play Store review checks the app's actual behavior
/// against.
const _termsText = '''
Last updated: 27 August 2026

These Terms & Conditions govern your use of the TS Minicab app as a driver
or administrator. By creating an account or continuing to use the app, you
agree to these terms.

1. Who can use this app

The app is for TS Minicab's own drivers and administrative staff only —
it's not a public-facing booking app. Drivers must be at least 18 years
old, hold a valid private hire vehicle driver's licence, and provide
accurate registration information. Administrator accounts are created and
managed by TS Minicab directly.

2. Your account

You're responsible for keeping your login credentials secure and for all
activity under your account. Tell us immediately if you believe your
account has been accessed without your permission. Information you provide
(name, contact details, documents, bank details) must be accurate and kept
up to date.

3. Driver verification

Before you can accept jobs, you'll need to upload the verification
documents the app asks for (driving licence, private hire licence,
insurance, DBS certificate, MOT certificate, a vehicle photo, a driver
photo, and TfL PCO badge, as applicable). An administrator reviews and
either verifies or rejects each document. We may decline to approve, or
may suspend, a driver account if documents are missing, expired, rejected,
or otherwise don't meet our requirements.

4. Accepting and completing jobs

Available jobs are shown to approved drivers, who may accept one at a
time — you can't hold more than one active job simultaneously. Once
accepted, you're expected to carry out the job through to completion,
updating its status (start, arrived, passenger on board, completed) as you
go, so both the customer's booking and our administrators have accurate,
real-time status.

5. Cancellations

If you need to cancel a job more than 2 hours before its scheduled pickup
time, you may release it back to the pool directly in the app. If it's
within 2 hours of pickup, cancelling instead submits a request for
administrator review, with a required reason — the job stays assigned to
you until reviewed. If an administrator approves a late cancellation
request, it may result in a penalty note on your driver record, at the
administrator's discretion, taking into account the reason given.

6. Payments

Fares for jobs you complete are payable to you by TS Minicab via bank
transfer, using the bank details you provide in the app. Payment timing
and processing is managed by our administrators; you can see which of your
completed jobs have been paid and which are still outstanding from the
app's Earnings/Payments screens at any time.

7. Conduct

You agree to use the app honestly and professionally: providing accurate
job status updates, not misrepresenting completed work, and treating
customers and TS Minicab staff professionally. We may suspend or terminate
an account for a serious or repeated breach of these terms, fraudulent
activity, or conduct that puts passenger safety or our licence at risk.

8. Account suspension, rejection, and deletion

We may suspend, reject, or decline to approve a driver account at our
discretion, including for failing verification, policy breaches, or
compliance requirements tied to our operator licence. You can request
deletion of your own account at any time from the app's Settings screen —
see our Privacy Policy for what happens to your data when you do.

9. Availability

We aim to keep the app available and working correctly but don't guarantee
uninterrupted access — like any software service, it may occasionally be
unavailable for maintenance or due to circumstances outside our control.

10. Liability

The app is provided to support our dispatch operations. To the extent
permitted by law, TS Minicab isn't liable for indirect or consequential
losses arising from your use of the app, except where that liability can't
be excluded by law (for example, for fraud or for death or personal injury
caused by our negligence).

11. Changes to these terms

We may update these terms from time to time, for example as our service or
legal obligations change. If we make a material change, we'll update this
page and change the "Last updated" date above. Continuing to use the app
after a change means you accept the updated terms.

12. Governing law

These terms are governed by the laws of England and Wales.

13. Contact us

Questions about these terms can be sent to support@tsminicab.com.
''';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(_termsText, style: TextStyle(height: 1.5)),
      ),
    );
  }
}
