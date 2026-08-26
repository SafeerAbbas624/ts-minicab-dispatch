import 'package:flutter/material.dart';

/// Describes what this specific app actually does (confirmed against the
/// real feature set: no location/GPS tracking, no analytics/ads SDKs, no
/// in-app card payments — bank-transfer payouts, driver document uploads,
/// and Firebase push notifications are the only real data-handling
/// features). Deliberately doesn't claim anything the app doesn't do, so it
/// can't contradict what App Store/Play Store review checks the app's
/// actual behavior against. Not a substitute for a solicitor's sign-off
/// before real-world publication, but accurate to the system as built.
const _policyText = '''
Last updated: 27 August 2026

TS Minicab ("we", "us", "our") operates this app to run our private hire
vehicle dispatch service, connecting our drivers with jobs and giving our
office administrators the tools to manage bookings, drivers, and payments.
This policy explains what information the app collects, why, and how it's
handled — for both driver and admin users.

1. Information we collect

Account information: name, email address, phone number, and password (your
password is never visible to us in plain text — the app only ever sends it
over an encrypted connection to be verified). Drivers can optionally set a
profile photo URL.

Driver verification documents: PHV/private hire driver licence, vehicle
insurance, DBS certificate, MOT certificate, driving licence, a vehicle
photo, a driver photo, and TfL PCO badge, as required by law and by our
operator licence to verify you're eligible to drive for us. These are
reviewed by our administrators and marked verified or rejected.

Bank details: for drivers, the account details needed to pay out completed
jobs (sort code and account number). These are entered by you and stored
so our administrators can process payments — we don't use them for any
other purpose.

Job and trip information: pickup and drop-off addresses, pickup time,
customer name and contact number, fare, and any notes attached to a
booking. This is the operational data needed to run the dispatch service
itself.

Payment records: which jobs have been paid out to a driver, when, and
(optionally) a photo of the transaction slip as proof of payment.

Device and notification data: if you allow notifications, we register a
device token with Firebase Cloud Messaging (a Google service) so we can
send you job and account alerts (e.g. a new job is available, your
document was reviewed, a payment was made). We do not use this token for
anything besides sending you those notifications.

What we do not collect: this app does not track your location or GPS
position, does not use advertising or analytics tracking SDKs, and does
not process card payments in-app — driver payouts are bank transfers
arranged by our administrators outside the app.

2. How we use this information

We use the information above solely to operate the dispatch service:
verifying you're eligible to drive for us, assigning and tracking jobs,
processing driver payouts, letting administrators manage the driver roster
and respond to cancellation requests, and sending you the notifications
described above. We do not use your information for advertising, and we do
not sell it.

3. Who can see your information

Your account and document information is visible to our administrators,
who need it to run the dispatch service and verify driver eligibility.
Customer name/contact/route details on a job are visible to the driver
assigned to that job, so they can carry it out. We use Firebase (a Google
Cloud service) to deliver push notifications; Google processes the device
token needed to do that on our behalf, under Google's own terms. We don't
share your information with any other third party, and we never sell it.

4. Data retention

We keep job, payment, and document records for as long as needed for
legal, tax, and licensing-compliance purposes, even after an account is
closed. If you request account deletion (available any time from Settings
> Request Account Deletion), your ability to log in is disabled
immediately, and your personal profile information is removed shortly
after — job and payment records tied to your account are retained as
described above, as we're required to keep them.

5. Your rights

You can review and update most of your own account information directly
in the app (Settings). You can request a copy of the personal information
we hold about you, or ask us to correct it, by contacting us using the
details below. You can request account deletion at any time from Settings.

6. Security

We use encrypted connections (HTTPS) for all communication between the app
and our servers, and store your session credentials securely on your
device. Access to administrator tools is restricted to authorised TS
Minicab staff.

7. Children

This app is intended for our drivers and administrators, who must be
adults. It is not directed at, and we do not knowingly collect information
from, children.

8. Changes to this policy

If we make a material change to how we handle your information, we'll
update this page and change the "Last updated" date above.

9. Contact us

Questions about this policy, or a request relating to your data, can be
sent to privacy@tsminicab.com.
''';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Text(_policyText, style: TextStyle(height: 1.5)),
      ),
    );
  }
}
