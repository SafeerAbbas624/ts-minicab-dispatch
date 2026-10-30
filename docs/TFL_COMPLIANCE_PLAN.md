# TfL Technical Solution — gap plan

Audit date: 29 Oct 2026. Compares the TfL Technical Solution Document draft
(Claude Docs: "TS Minicab – Technical Solution Documentation") against what
is actually built today. **Every item below is described in the draft as if
it exists — it must be built, and verified live, before Tommaso signs the
section 6 declaration and before the TfL demo.** The demo must match the
document exactly.

Owner key: **APP** = this Flutter repo · **API** = backend session on the VPS ·
**WEB** = tsminicab.com · **OPS** = Tommaso / business admin, not code.

## Already built (no work needed)

- Operator acceptance before dispatch: website jobs start `pending_approval`, admin approves → `open`.
- Telephone bookings entered by admin (`POST /admin/jobs`, source `admin_manual`).
- Driver onboarding, document upload, admin document verify/reject, driver approve/reject/suspend; server 403s unapproved drivers.
- Driver accept with 409 race + 2h overlap guard; status sequence en_route → arrived → passenger_on_board → completed with skip-guard.
- Driver withdrawal: immediate release >2h, operator review ≤2h, approve/reject with penalty flag.
- Admin assign to named driver, reopen to pool, cancel with reason.
- `JobEvent` history per job (actor, note, timestamp) shown in admin job detail; admin Action Log with descriptions.
- Push to admins and drivers for every job stage (20 triggers, `data.type` routed).
- TfL weekly export + CSV. Auth rate limiting. Bank details encrypted. Token in secure storage. Privacy policy, terms, account deletion.

## To build

### P1 — the document's core claims (TfL will test these in the demo)

| # | Gap | Owner | Work |
|---|-----|-------|------|
| 1 | **Passenger notifications** — nothing is sent to passengers today | API, WEB | SMS + email at: booking received, operator accepted, driver assigned (name, photo, PHV licence no., vehicle make/model/colour/reg), driver changed, en route, arrived, cancelled (+reason), completed + receipt. Pick SMS provider (e.g. Twilio / Vonage / ClickSend). Log every send as a `JobEvent` (`notification_sent`, channel, provider message id, status). |
| 2 | **Booking reference + "Manage my booking" page** | WEB, API | Human-readable reference on every job; tokenised public link showing status, driver/vehicle details, Cancel button. Endpoints `GET /public/bookings/:ref?token=`, `POST .../cancel`. |
| 3 | **Passenger self-cancellation (5b)** | WEB, API | Cancel via the page above → status `cancelled`, `JobEvent` actor=passenger, driver push "job cancelled", admin push. |
| 4 | **Mobile OTP verification on website bookings** | WEB, API | `POST /public/bookings/verify-phone`, code required on submit. |
| 5 | **Verification checks logged** | API | On booking create: duplicate-booking check, blocked-customer list (admin-managed), restricted-location check, pickup-in-future. Write one `JobEvent` `verification_completed` with results. |
| 6 | **Driver must not see passenger phone** | APP, API | Today `customerContact` is shown on the **open jobs list to every driver** (`job_card.dart:69`, `active_job_view.dart:232`, `job_detail_screen.dart:80`). Remove from driver UI and strip from `/jobs/open` and `/jobs/mine` responses server-side. Driver sees passenger name + booking ref only; add "Call operating centre" button. |
| 7 | **Driver notified when operator/passenger cancels** | API | Push `job_cancelled` to the assigned driver on any cancellation; app removes it from active jobs. Check whether this already exists among the 20 triggers. |
| 8 | **Passenger notified on reassignment (5c-i) and on operator cancel (5c-ii, 5d)** | API | Hook into `/assign`, `/reassign`, `/cancel`, cancellation-request approve. |
| 9 | **Unassigned-booking alert (5d)** | API | Scheduled job: booking `open` with no driver N min (decide: 60) before pickup → admin push + dashboard flag + `JobEvent`. |
| 10 | **Millisecond audit log screen + CSV export** | APP, API | Confirm `JobEvent.createdAt` is `timestamp(3)` (Prisma default — verify). New admin "Booking Audit Log" screen: filter by date/ref/driver/status, show `hh:mm:ss.mmm`, CSV export (`GET /admin/audit-log`). Add missing event types: `created`, `verification_completed`, `operator_accepted` (with admin user), `dispatched` (drivers notified count), `notification_sent`, `cancelled` (actor type). |
| 11 | **Offline handling** | APP | `connectivity_plus` → "Offline" banner on driver + admin shells; disable accept/status buttons while offline; auto-refresh on reconnect. Action is only shown as done after server 2xx (already true — verify). |
| 12 | **Driver vehicle details** | API, APP | Confirm Vehicle has make, model, colour, registration, PHV vehicle licence no.; admin can view/edit. Needed for passenger notification (#1). |

### P2 — compliance and security claims

| # | Gap | Owner | Work |
|---|-----|-------|------|
| 13 | **Document expiry tracking** | APP, API | Expiry date picker on driver document upload (repo already sends `expiry_date`, no UI). Daily job: reminders at 30/14/7 days (driver + admin push/email); auto-block job endpoints when a required doc is expired. Show expiry on admin driver detail. |
| 14 | **PHV vehicle licence document type** | API, APP | Add `phv_vehicle_licence` to `DocumentType`; required for approval. |
| 15 | **Admin two-factor authentication** | API, APP | Email OTP (reuse OTP infra) or TOTP on admin/super_admin login. |
| 16 | **Revoke sessions (lost/stolen device)** | API, APP | Token version per user; `POST /admin/users/:id/revoke-sessions`; button on driver detail. Shorten JWT expiry if long. |
| 17 | **Restricted locations** | API, APP | Admin-managed list (postcode/area + reason); booking create blocks or flags. |
| 18 | **No hard deletes of jobs; deletion anonymises driver** | API | Verify `DELETE /admin/drivers/:id` and account deletion keep Job/JobEvent rows (anonymise profile only). 12-month minimum retention. |
| 19 | **Automated encrypted backups** | API / OPS | Nightly `pg_dump` + files, encrypted, to off-server UK storage, 30-day retention, monthly restore test. **Still not done.** |
| 20 | **Uptime + error monitoring** | API, APP | Uptime monitor on `/health`; Sentry/Crashlytics. |
| 21 | **Staging environment** | API | Separate staging API + DB for testing releases (doc section 4 says so). |
| 22 | **Receipt email** | API | On `completed`. Depends on #1. |

### P3 — paperwork (OPS, no code)

| # | Item |
|---|------|
| 23 | ICO registration (data protection fee) — get number for section 4. |
| 24 | Cyber Essentials certification (self-assessment, ~£320+VAT) — the realistic "ISO 27001 equivalent". |
| 25 | DPIA, Record of Processing Activities, breach procedure, retention schedule — written documents. |
| 26 | Data processing agreements: VPS host, email provider, SMS provider, Firebase (Google DPA). |
| 27 | External vulnerability scan + keep the report. |
| 28 | PHV compliance checklist + release change log (section 4). |
| 29 | Fill every `[CONFIRM …]` in the draft: company name/number, operating centre, VPS provider + data-centre city, DB engine, SMTP/SMS providers, payment method, Android min version, build numbers, dates. |
| 30 | Emergency contact form — second contact (from the TfL email). |

### Demo preparation

- 3 driver test accounts on 3 devices, 2 passenger devices (website), admin panel on a laptop/screen.
- Rehearse all scenarios incl. drivers offline when the operator accepts, and airplane-mode tests.
- Capture real timestamped exports + screenshots for 5.1 from staging after P1 is built; replace the template rows in the draft.

## Suggested order (≈ 4 weeks)

1. Week 1: #6 (quick, privacy risk today), #10, #12, #19, start #23–#26.
2. Week 2: #1, #2, #3, #4, #7, #8 (passenger channel — biggest piece, mostly API + WEB).
3. Week 3: #5, #9, #11, #13, #14, #15, #16.
4. Week 4: #17, #18, #20–#22, staging demo rehearsal, capture logs/screenshots, finalise doc.
