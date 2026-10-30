# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

One Flutter (Material 3) design used unchanged on Android, iPhone and the web admin panel at app.tsminicab.com (confirmed: same design everywhere, no per-OS adaptation).

## Users

- **Drivers** — licensed London private hire (PCO) drivers working for TS Minicab. They use the app in the car: accepting jobs, moving each job through en route → arrived → passenger on board → complete, uploading licensing documents, checking earnings. Often one-handed, in daylight glare or at night, alongside a navigation app.
- **Operators / dispatchers** — Tommaso (super admin, dispatcher name "Tommaso") and any admins he creates, at a desk in the operating centre. They approve website bookings, enter telephone bookings, assign and reassign drivers, review driver documents, handle cancellations, pay drivers and export TfL data.
- **TfL licensing officers** — not daily users, but they evaluate the admin panel and driver app in a live demonstration and in screenshots attached to the operator licence application.

Drivers and operators are equally important to the redesign (confirmed).

## Product Purpose

TS Minicab Dispatch is the booking-records and dispatch system for TS Minicab, a London private hire operator. Passengers book on tsminicab.com or by phone; the operating centre accepts every booking before it reaches drivers; drivers accept and carry out jobs; every step is recorded with a millisecond timestamp. Success means every journey is dispatched to a licensed, in-date driver, the passenger is kept informed at each stage, and the operator can prove all of it to TfL.

## Positioning

A small, owner-run London operator's own system: the operator — a named dispatcher — personally accepts every booking, drivers never contact passengers directly (everything goes through the operating centre), and licensing compliance (document expiry, call signs, TfL export, audit log) is built into the daily workflow rather than bolted on.

## Operating Context

- Passenger touchpoints are outside this app: tsminicab.com booking flow, booking emails from booking@tsminicab.com, and the private tracking / manage-booking page (tsminicab.com/track/<token>) with a self-hosted map.
- Driver app: Google Play and Apple App Store, "TS Minicab". Admin panel: same build on the web.
- Booking references look like TS-10001; driver call signs like TS001.
- Times are London time (GMT/BST) everywhere.
- Push notifications (Firebase) and email only — no SMS.
- TfL Technical Solution documentation and a live demo (3 drivers, 2 passengers, admin) are pending.

## Capabilities and Constraints

- Job statuses: pending_approval → open → accepted → en_route → arrived → passenger_on_board → completed, plus cancelled; driver withdrawal within 2 hours of pickup goes to operator review.
- Drivers must hold verified, in-date documents (driver photo, licence front/back, TfL PCO badge, vehicle photo, MOT, hire & reward insurance, PHV vehicle licence, V5C, permission letter if not the keeper); expired documents block taking jobs.
- Drivers never see the passenger's phone or email; they see the operating centre number (+44 20 3679 2664).
- Live location is shared only from Start Job until the job ends.
- Admin roles: super_admin (can create/rename/remove admins), admin, demo_admin; demo_driver accounts exist for app-store review.
- Light and dark themes, selectable by the user.

## Brand Commitments

- Name: TS Minicab. Logo: assets/branding/logo.png (navy line art of London landmarks and a cab, orange swoosh) and the dark-mode variant assets/branding/logo_dark.png.
- Brand colours and typeface come from tsminicab.com: navy #0E2A4D (with #081A30 / #16385F), orange #E2560B, font Figtree.
- Personality: premium and reliable — a calm, confident professional car service (confirmed).

## Evidence on Hand

- Real operator phone, booking email and website: +44 20 3679 2664, booking@tsminicab.com, tsminicab.com.
- No customer testimonials, ratings or volume figures are recorded for use in the app; do not invent any.

## Product Principles

1. The operator is in control: every booking is accepted, assigned and recorded by a named dispatcher.
2. One clear next step: at any moment a driver should know the single action to take.
3. Compliance is visible, not hidden: expiry, verification and audit state are shown where decisions are made.
4. Nothing is shown as done until the server confirms it; offline is stated plainly.
5. What TfL sees in the demo must match the documentation exactly.

## Accessibility & Inclusion

Used in moving-vehicle contexts: large touch targets, high contrast in both themes, legible at arm's length; no information conveyed by colour alone.
