# iOS release without a Mac (Codemagic)

iOS builds run on Codemagic's macOS machines from `codemagic.yaml`, are signed
automatically with an App Store Connect API key, and are uploaded to
TestFlight. Submission for review is done by hand in App Store Connect.

App: **TS Minicab**, bundle ID `com.tsminicab.dispatch`, minimum iOS 15.

## One-time setup (account owner)

These steps involve creating an account, granting access and handling an API
key, so the account owner does them.

1. **App Store Connect API key** — App Store Connect → Users and Access →
   Integrations → App Store Connect API → Team Keys → **+**.
   Name `Codemagic`, access **App Manager**. Download the `.p8` file (it can
   only be downloaded once) and note the **Issuer ID** and **Key ID**.
2. **Codemagic account** — sign up at codemagic.io with GitHub and give it
   access to the `ts-minicab-dispatch` repository.
3. **Add the key to Codemagic** — Team settings → Integrations → **Developer
   Portal** → Manage keys → Add key. Name it exactly
   **`TS Minicab App Store Connect`**, then enter the Issuer ID, Key ID and
   `.p8` file.
4. **App's Apple ID** — App Store Connect → the app → App Information →
   **Apple ID** (a number). In Codemagic: the app → Environment variables →
   add `APP_STORE_APPLE_ID` = that number, group **`ios_release`**.
5. **Push notifications** — check Firebase console → Project settings → Cloud
   Messaging → Apple app configuration has an **APNs Authentication Key**
   uploaded (it should be, since push works in the current version).

## Building

In Codemagic, start a build on the release branch and pick a workflow:

- **iOS — staging build to TestFlight** (`ios-staging`): uses the staging
  API. Add it to an *internal* TestFlight group only, for testing on an
  iPhone before go-live.
- **iOS — production build to TestFlight** (`ios-production`): uses the live
  API. This is the build submitted for review.

The build number is set automatically to one above the latest TestFlight
build; the version (e.g. 1.1.0) comes from `pubspec.yaml`. A finished build
appears in App Store Connect → TestFlight after Apple's processing (10–30 min).

## Submitting for review

App Store Connect → the app → **+ Version** (same version as `pubspec.yaml`)
→ select the production build → fill in "What's New" → add the review notes
below → Submit for Review.

### What's New (suggested)

> - Redesigned app with a clearer job screen and one-tap next step
> - Live journey tracking for passengers while a job is under way
> - Driver profile, vehicle details and document expiry reminders
> - Call the operating centre directly from any job

### App Review notes (paste into "Notes" under App Review Information)

> TS Minicab is the driver and operator app for TS Minicab, a London private
> hire (minicab) operator licensed by Transport for London. Only drivers
> approved by our operating centre, and our own operators, can sign in.
>
> **Location (including background):** location is collected only while a
> driver is carrying out a job, from the moment they tap "Start job" until
> the job is completed or handed back. During that time the driver's
> position is shown to that job's passenger on their private booking-tracking
> page, so they can see the car arriving. The app shows an in-app explanation
> before the system permission prompt, and a blue location indicator while
> sharing. Location is never collected when the driver has no job in
> progress. Background mode is needed because drivers use a navigation app
> while on the way to the pickup.
>
> **Demo account:** a demo driver account is provided in the sign-in
> information. It is pre-approved and has a sample job so the job flow
> (Start job → Arrived → Passenger on board → Complete) can be tried.
>
> **No direct passenger contact:** drivers cannot see passengers' phone
> numbers or emails; all contact goes through our operating centre.

Use the same demo reviewer account as the previous review (see
`secrets/demo-reviewer-credentials.md`), and make sure it has a sample job
in an active state before submitting.

## Things to check on a real iPhone (TestFlight)

- Location permission prompt shows our explanation; tracking page updates
  while the app is in the background (e.g. with Google Maps open).
- Push notifications arrive for new jobs and job changes.
- Document upload (camera roll / files) works.
- "Call operating centre" opens the phone dialer.
- Dark mode and the new logo.
