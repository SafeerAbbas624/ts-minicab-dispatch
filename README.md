<p align="center">
  <img src="assets/branding/logo.png" alt="TS Minicab logo" width="320">
</p>

# TS Minicab — Dispatch App

A single Flutter codebase for TS Minicab's driver and admin dispatch system — one app, one App Store listing, one Play Store listing. Which panel a user sees is decided entirely by the `role` the backend returns at login: admin-family roles (`admin`, `super_admin`, `demo_admin`) land in the **Admin panel**; driver-family roles (`driver`, `demo_driver`) land in the **Driver panel**.

There is no customer-facing app, no maps/location SDK, and no in-app payment processing — payouts are wire transfers tracked through the admin "mark paid" flow only.

## What's in each panel

**Driver panel**
- Signup → email OTP verification → pending-admin-approval holding state
- Document upload (PHV licence, insurance, DBS, MOT) with per-document verified/pending status
- Bank details, avatar, theme, password — settings
- Open jobs list (sorted soonest pickup first) → full details → accept, with an explicit "someone else got this one" flow on the 409 race
- Active job screen: Arrived / Trip Completed / Can't Complete (with reason)
- Job history (Paid / Completed & Unpaid), earnings summary
- Request Account Deletion, with the required disclosure of what happens to their data

**Admin panel**
- Driver approval queue (review documents, approve/reject/suspend), driver detail with notes log and bank info
- Create additional admin accounts (`super_admin` only — hidden entirely for regular admins)
- Manual job posting, website-sourced jobs queue (approve/edit before drivers see them), active jobs overview (cancel/reassign)
- Completed jobs → mark paid, with optional transaction slip upload
- TfL export (table view + CSV download), analytics dashboard, read-only admin action log

Both `demo_admin` and `demo_driver` are full, real accounts (not a stripped-down demo mode) — they exist so App Store/Play Console reviewers can exercise every feature. See [Demo accounts](#demo-accounts) below.

## Stack

| Concern | Choice |
|---|---|
| Framework | Flutter (Dart), single codebase for iOS + Android |
| State management | Riverpod |
| HTTP | dio, with an interceptor for JWT attachment and 401 handling |
| Token storage | flutter_secure_storage (never SharedPreferences) |
| Routing | go_router, with role-based redirects |
| Push notifications | firebase_messaging (code is written and ready; not yet activated — see [Push notifications](#push-notifications-not-yet-active)) |
| File uploads | file_picker + dio multipart |

## Project structure

```
lib/
  core/            # config, network client, models, routing, theme, shared utils
  features/
    auth/           # login, signup, OTP, password reset, privacy policy
    driver/         # driver panel: jobs, documents, bank details, settings
    admin/          # admin panel: drivers, jobs, payments, TfL export, analytics
docs/
  API_CONTRACT.md   # the fixed API contract this app is built against, plus
                    # field-level reconciliation notes from testing against
                    # the real backend (casing quirks, confirmed gaps, etc.)
secrets/            # gitignored — local-only credentials, never committed
```

## Getting started

```bash
git clone https://github.com/SafeerAbbas624/ts-minicab-dispatch.git
cd ts-minicab-dispatch
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.tsminicab.com
```

`API_BASE_URL` defaults to the production URL (see `lib/core/config/env.dart`) if you omit the flag — pass a different value to point at a staging/local backend instead.

### Requirements

- Flutter SDK (stable channel) — this project currently targets 3.47.x
- For Android: Android Studio + the Android SDK, a device or emulator
- For iOS: a Mac with Xcode + CocoaPods (Apple's tooling requirement — iOS builds cannot be produced on Windows/Linux)

Run `flutter doctor` to check your setup.

## Demo accounts

Reviewer-access credentials (`demo_admin` / `demo_driver`) are issued by the backend and are **not stored in this repository**. If you need them, they live in `secrets/demo-reviewer-credentials.md` on the machine they were issued to (gitignored — see `.gitignore`) — ask whoever holds that file, or regenerate them from the backend's seed process if lost.

## API contract

This app is built against a fixed API contract owned by the backend (`https://api.tsminicab.com/api`), documented in full in [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — including field-level casing notes (the API mixes snake_case and camelCase depending on endpoint, which isn't guessable from route names alone) and a list of confirmed gaps between what the app needs and what the backend currently exposes.

## Push notifications (not yet active)

The Dart-side service (`lib/core/push/`) is written and ready to register device tokens and handle refresh, but isn't called from `main.dart` yet — it's waiting on `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from the Firebase console. Wiring up `Firebase.initializeApp()` before those files exist breaks the Android build, so this is deliberately left inactive until they're available.

## What's explicitly out of scope

No maps or location SDK, no in-app payment processing (Stripe/Apple Pay/Google Pay), no direct database access from the app, no flight-tracking integration, no social login — these are intentional constraints from the product spec, not gaps.
