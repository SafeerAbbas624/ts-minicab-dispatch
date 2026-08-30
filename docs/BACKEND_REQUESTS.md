# Backend requests — feature round, 24 Aug 2026

Everything below is needed to finish the feature list requested on this date. Each item says what's missing, why, and a suggested shape — the backend session should treat the suggested shape as a starting point, not a spec set in stone. Client-side work that depends on each item is noted so priority can be judged.

**Status, 26 Aug 2026: everything through item 9 is closed out.** All 6 original items delivered and live, client-side wiring done and live-verified. The two item 5 follow-up bugs (`penalize: false`, review-note field-name mismatch) are fixed and re-verified live; item 4's phone-number gap is fixed; item 7 (`POST /push-tokens` 403 for admins) is fixed. Item 8 is decided (Option C — see below); item 9's `data.type` payload is delivered, verified live end-to-end, and the client now routes on it instead of matching title text. Item 10 (two new job-status steps, Start Job/Passenger On Board, with notifications) is delivered, live-verified, and fully wired client-side. Item 11 was a client-only fix, no backend involved. **Open decision (not a bug):** should admin reassign/assign extend to the two new mid-trip states — see item 10's note. Item 12 (`/push-tokens` platform enum missing `"web"`) is fixed and re-verified live, 28 Aug — web push registration works end-to-end now. **Pre-launch, 30 Aug — all closed.** Item 1's rework (time-overlap check replacing the flat one-active-job rule) is live and independently verified end-to-end. Item 13 (auth rate limiting) is live on all 5 auth endpoints. Item 14's production data wipe is done — only `demo_admin`/`demo_driver` remain, verified live. **Only remaining pre-launch item, not tracked here since it's not backend code: automated database backups still don't exist** — the user is handling this manually, flagged so it doesn't get lost.

## 1. Prevent a driver from holding more than one active job at once

**Confirmed live, reproducible every time:** `POST /jobs/:id/accept` currently lets the same driver accept any number of jobs simultaneously, even ones that overlap in time. Tested by creating two jobs (pickup 3h and 6h out) and accepting both back-to-back as the same driver — both succeeded, no 409, no rejection at all.

**Needed:** before accepting, reject with 409 if the driver already has a job in `accepted` or `arrived` status. Recommended: block on *any* existing active job, not just time-overlapping ones — simplest to implement, and safest from a dispatch-integrity standpoint (a driver mid-job accepting a same-day job "for later" is exactly the kind of thing that goes wrong when the first job runs long). If sequential non-overlapping jobs should be allowed instead (driver 1 holds an 8am, 11am, and 2pm job simultaneously), that needs a time-window overlap check instead of a flat one-active-job rule — worth deciding explicitly rather than defaulting to it.

**Client impact:** none needed once this lands — the driver app already only shows one "active job" slot in its UI; it just isn't backed by a server-side guarantee yet.

**Reopened, 29 Aug — decision reversed.** This was built as the flat "block on any active job" rule (confirmed live, still enforced today). The user now wants the other option: a driver holding an active job should still be able to browse and accept *other* jobs, as long as they don't overlap in time.

**Needed — updated shape:** change `POST /jobs/:id/accept`'s check from "driver has any job in `accepted`/`en_route`/`arrived`/`passenger_on_board`" to a time-window overlap check against the driver's other active jobs' `pickupDatetime`. There's no trip-duration/estimated-dropoff field on a job, so "overlap" needs a policy buffer rather than exact time math — suggest reusing the 2-hour window already established elsewhere in this system (the cancellation cutoff) as the minimum gap required between two of a driver's active jobs' pickup times, unless you'd rather define it differently. 409 (same as today) if the new job's pickup falls inside that buffer around any existing active job.

**Client impact:** done and deployed, 30 Aug — the Jobs tab now shows every one of a driver's active jobs as a compact card in a horizontal strip (tap through to the full step controls), with the open-jobs list still reachable underneath either way. Accepting a second job goes through the same existing flow/error handling as any accept, so no extra logic was needed for the conflict case itself.

**Confirmed live end-to-end, 30 Aug** — tested directly against the real API with real demo_driver/demo_admin tokens, not just taking the backend session's report at face value: created 3 test jobs (A at +3h, B at +6h, C at +3h30m), accepted A (200), accepted B (200, 3h apart from A — no conflict), attempted C (409, `"This job's pickup time is too close to another job you're already assigned to (must be at least 2h apart)"`, exactly 30 min from A). Confirmed `GET /jobs/mine` shows A and B both `status:"accepted"` simultaneously. Test jobs cancelled/cleaned up afterward. Auth rate limiting also confirmed live per the backend's own report (login 10/15min, signup 5/60min, OTP verify 10/15min, password-reset request 5/60min, submit 10/15min).

## 2. Document viewing and verification for admins

**Confirmed via the earlier API reference reconciliation:** `file_path`/`filePath` on a document record is a server filesystem path, not anything the app can load. There is no endpoint that serves the actual file content, and no endpoint that lets an admin mark a document verified or rejected — `verified_by_admin`/`verified_at` exist as fields but nothing ever sets them from the admin side today.

**Needed:**
- A way to fetch the actual file — either `GET /admin/drivers/:driver_id/documents/:document_id/file` streaming the raw bytes, or the document list response switching to a signed/temporary URL the app can load directly (`Image.network`/PDF viewer). Same gap exists driver-side for the driver's own documents, if drivers should be able to review what they uploaded.
- `POST /admin/drivers/:driver_id/documents/:document_id/verify` and a reject counterpart (with a reason, mirroring how job cancellation already asks for one) — sets `verified_by_admin`/`verified_at`.

**Client impact:** built and live-verified — admin document-review dialog (image preview via `Image.memory`, or "Open PDF" via share_plus for PDFs) with Verify/Reject actions, reachable by tapping any document row on the driver detail screen.

## 3. New document types

Current `DocumentType` enum: `phv_licence | insurance | dbs | mot | other`. Confirmed: add four upload types — driver's licence, car (vehicle) picture, driver's own photo, and TfL PCO badge (a photo upload, not a text field).

**Delivered exactly as suggested** — confirmed live by surfacing a deliberately-invalid `document_type` and reading the validation error, which listed the full enum: `phv_licence | insurance | dbs | mot | other | driving_licence | vehicle_photo | driver_photo | tfl_pco_badge`.

**Client impact:** built and live-verified — the driver's document-type picker and the admin verification screen from item 2 both show all 4 new types with human-readable labels (Driver Licence, Car Picture, Driver Picture, TfL PCO Badge).

## 4. Direct driver reassignment

**Confirmed via the API reference and live testing:** `POST /admin/jobs/:id/reassign` only unassigns the current driver (`accepted → open`, clears `currentDriverId`) — it reopens the job to the general pool for any approved driver to self-accept. There's no way for an admin to assign a job directly to a *specific* driver; only a driver's own authenticated accept call can do that today.

**Needed:** a new endpoint, e.g. `POST /admin/jobs/:id/assign` with `{"driver_id": "..."}` — sets `currentDriverId` and status directly (bypassing the normal self-service accept race), presumably validating the target driver is `approved`/`active`. Whether the existing reassign-to-pool behavior should stay as a separate action or be replaced entirely by "reassign always means pick a specific driver" is a product call — the client can support either.

**Client impact:** built and live-verified — the driver picker now calls the real `/assign` endpoint. Wired into both the Accepted Jobs tab's "Reassign" (with "Reopen to general pool" still pinned at the top) and the Active Jobs tab's new "Assign to driver" action, confirmed `/assign` works from `open` status too. `GET /admin/drivers` now returns `phone_number` (fixed 25 Aug) — search matches name, email, or number (digit-only comparison so punctuation/country-code formatting doesn't matter).

## 5. Cancellation-request/approval workflow with a 2-hour cutoff

This is the biggest new piece — a genuinely new workflow, not an extension of an existing one.

**Requested behavior:**
- More than 2 hours before pickup: a driver can cancel an accepted job immediately, same as today (`POST /jobs/:id/release`).
- Less than 2 hours before pickup: the driver can no longer cancel outright. Instead they submit a cancellation **request** with a required reason. The job stays assigned to them, shown as "pending cancellation," until an admin reviews it.
- Admin reviews the request: if approved, the job is actually released/reopened and the driver is penalized (mechanism TBD — see below). If not approved, the job simply stays assigned as normal — nothing changes.

**Delivered and verified live — actual shape differs from my original suggestion below, documented for the record:**
- `POST /jobs/:id/request-cancellation` (driver) — body `{"reason": "..."}`. Confirmed this is the single entry point for both cases: the backend itself checks time-to-pickup — more than 2 hours out, the job is released immediately (no request row created); under 2 hours, a pending `CancellationRequest` is created instead and the job stays assigned until reviewed.
- `GET /admin/cancellation-requests` — confirmed live, returns all requests (pending/approved/rejected) with the job and driver nested.
- Two separate endpoints, **not** a unified `/review` as I originally suggested: `POST /admin/cancellation-requests/:id/approve` (body `{"reviewNote": "...", "penalize": true|false}`) and `POST /admin/cancellation-requests/:id/reject` (body `{"note": "..."}`). Approve releases the job back to the pool; reject leaves it assigned, nothing changes.
- **Both follow-up bugs fixed and re-verified live (25 Aug):** `penalize: false` now correctly skips the driver-notes write (confirmed: notes count unchanged after a `penalize: false` approve, incremented as expected after a `penalize: true` one on a fresh request). The review-note field-name mismatch (`reviewNote`/`note` from the client vs. a schema that only recognized `review_note`) is fixed — the endpoints now accept `review_note`, `reviewNote` (approve), and `note` (approve or reject) interchangeably; confirmed `reviewNote` persists correctly in the `GET /admin/cancellation-requests` response for both approve and reject.

**Client impact:** built and live-verified — driver-side warning dialog (copy below) wired to `request-cancellation`, a "Pending cancellation" banner that disables the active-job actions, and an admin Cancellations inbox tab with Approve/Reject (penalty-note warning removed from the approve dialog now that the toggle works correctly).

**Suggested dialog copy** for the driver-side cancellation-request flow (shown when a driver tries to cancel within 2 hours of pickup):

> **Cancelling this close to pickup**
>
> This job is due within 2 hours. Cancelling now may leave us unable to arrange another driver in time, so this won't cancel the job immediately — it'll be sent to an admin for review.
>
> Please explain why you need to cancel. If the cancellation is approved, it may result in a penalty on your account.
>
> [Reason text field]
>
> [Back]  [Submit for review]

## 6. Job event / status history for the admin job-detail view

The new admin job-detail popup shows current status, but not a timeline of what's happened to the job (accepted at X, arrived at Y, etc.) — that's the `JobEvent` model, which per the API reference "isn't directly exposed via any GET route yet." If a running history/notification feed in the popup is wanted (not just current status), this needs `GET /admin/jobs/:id/events` or the events nested directly in the job detail response.

**Client impact:** built and live-verified — the job detail popup now has a History section listing every event (created, opened, accepted, etc.) with timestamp, actor, and note, confirmed rendering real data including the "Assigned directly by admin" note from item 4's `/assign` endpoint.

## 7. `POST /push-tokens` returns 403 for admin accounts

**Confirmed live, 25 Aug:** tested this endpoint directly with both an admin token and a driver token, same request body. Driver token → `201 {"message": "Push token registered"}`. Admin token (demo_admin) → `403 Forbidden`, empty body. This directly contradicts the API reference's own note that the endpoint is "role-agnostic" and admins should register through it too — right now only drivers actually can.

**Impact today:** the admin app calls this on every login/session-restore (fire-and-forget, doesn't block anything) and it always fails with 403, so no admin device is currently registered for push — none of the "To admins" notifications documented in the Push notifications reference section (job-needs-approval alerts, etc.) can reach anyone right now.

**Needed:** whatever permission check is rejecting admin/super_admin/demo_admin roles on this route needs removing — the client already calls it correctly (confirmed matching the documented `{"device_token", "platform"}` shape) and doesn't need any change once this is fixed.

**Client impact:** none needed — already wired up and calling correctly; this is purely a server-side fix.

**Update 25 Aug:** confirmed fixed by the backend session (root cause was `/push-tokens` living inside `jobsRouter`, gated `requireRole('driver', 'demo_driver')` — moved to its own router gated only by `requireAuth`). Not yet re-verified independently on this side, but no client change needed either way.

## 8. Dashboard analytics vs. Payments/Jobs screens show different scopes of data — needs a product decision, not a bug fix

**Found while investigating a reported discrepancy** ("Outstanding unpaid" showing £0.00 on the dashboard while the Payments screen's Unpaid tab shows real unpaid jobs). Root-caused via live testing, not a guess:

- `GET /admin/analytics` excludes demo-account activity (`demo_admin`/`demo_driver`) from every total — confirmed by creating jobs/payments as demo_driver and watching `total_jobs`, `completed_jobs`, `total_revenue_paid` all stay unaffected. This looks intentional (keeps demo/reviewer activity out of real business metrics) and is documented as such in an earlier round.
- `GET /admin/payments` and `GET /admin/jobs` do **not** exclude demo accounts — they return everything, demo or real.
- The client's Payments > Unpaid tab is derived from `GET /admin/jobs?status=completed` (see the comment in `payment_list_screen.dart` — the backend only ever creates a Payment row at the moment something's marked paid, never on completion, so `?status=unpaid` is structurally always empty and unusable for this).

Net effect: any demo-account job (which happens constantly during QA testing with demo_admin/demo_driver) shows up in Payments/Jobs but is invisible on the Dashboard — not a data-loss bug, just two screens with inconsistent scope. Reproduced concretely: completed 2 demo_driver jobs (fares £44 and £33, neither paid) — Payments > Unpaid showed them correctly, Dashboard's Outstanding unpaid stayed £0.00 throughout.

**Needed — your call, not something to fix blind:**
- Option A: make `GET /admin/payments` and `GET /admin/jobs` exclude demo accounts too, matching Analytics, so every admin screen agrees. Downside: demo/QA activity becomes invisible everywhere, not just on the dashboard.
- Option B: leave the backend as-is (demo accounts stay useful for QA) and the client-side Payments/Jobs screens filter demo accounts out to match Analytics' scope — doable purely client-side once the backend can flag which accounts are demo (a `role` field is already in the driver list, so this might not even need a backend change — worth confirming account roles are present everywhere the client would need to filter on).
- Option C: leave both as-is and just label the scope difference clearly in the UI (e.g. "excludes demo accounts" caption on the dashboard cards) so it reads as intentional rather than broken.

Given demo_admin/demo_driver are real, ongoing App Store/Play Store reviewer accounts (not just internal test data), Option C is the safest change — smallest blast radius, no risk of leaking demo activity into anything, and no behavior change. Flagging this as a decision rather than picking one myself.

**Decided 25 Aug: Option C.** No backend change — both scopes stay exactly as they are (Analytics/TfL export excludes demo accounts, Payments/Jobs doesn't).

**Client impact:** done — added an "Excludes demo/reviewer account activity" caption above the dashboard's stat cards so the scope difference reads as intentional.

## 9. Push notification payload needs a stable routing key

**Context:** built the client's foreground-notification display and tap-to-navigate handling this round (Android didn't show anything at all while the app was open — flutter_local_notifications is now wired in for that). Tap-routing on the admin side jumps to the right tab, but per the Push notifications reference section, the payload is a plain `{notification: {title, body}}` with no custom data — so routing has to match on the literal title string (e.g. `"Job completed"` → Jobs > Completed tab). This is fragile: any future wording change to a notification title silently breaks its routing with no error, and there's no way to route to a *specific* job/driver, only a tab.

**Needed:** add a small `data` payload alongside the existing `notification` block — even just `{"type": "job_completed", "job_id": "...", "driver_id": "..."}` (or similar, whatever's easiest given payload code that already exists per notification type) would let routing key off a stable code instead of English text, and open the door to deep-linking straight to the specific job/driver instead of just the containing tab.

**Delivered 25 Aug** — every push now carries `data.type` plus whichever ids apply (job_id/driver_id/document_id/payment_id/request_id, all strings, omitted rather than `"null"` when not relevant), covering all 20 triggers across every route file. Verified both structurally (a direct Firebase Admin SDK call) and end-to-end (a real admin device token registered, a job-accept triggered, delivery confirmed, cleaned up).

**Client impact:** done — `push_notification_service.dart` now routes on `data['type']` (a fixed switch over the "To admins" type codes) instead of matching title text. Deep-linking to the *specific* record (not just the containing tab) isn't built yet — no screen currently supports opening a job/driver detail by id from outside its list — but the ids are already flowing through so that's addable later without another backend round-trip.

## 10. Two new job-status steps: "Start Job" and "Passenger On Board"

**Requested:** the driver's active-job flow currently only has two steps after accepting — Arrived, then Completed. Wanted: four — **Start Job → Arrived to Pickup → Passenger On Board → Clear/Done** — with a push notification at each step, same as the existing ones.

Two of these four already exist and needed no backend change — I relabeled the buttons client-side (`active_job_view.dart`): "Arrived" → **Arrived to Pickup** (still posts `status: "arrived"`), "Trip Completed" → **Clear / Done** (still posts `status: "completed"`). The other two are genuinely new states with no current backend representation, so the buttons for them aren't wired up yet — building them as no-op UI would be dishonest since nothing would persist, no admin would see it, and no notification would fire.

**Needed — suggested shape, naming is yours to change:**
- Two new `JobStatus` values inserted into the sequence: `en_route` (between `accepted` and `arrived` — driver tapped "Start Job") and `passenger_on_board` (between `arrived` and `completed` — driver tapped "Passenger On Board"). Full sequence becomes `accepted → en_route → arrived → passenger_on_board → completed`.
- `POST /jobs/:id/status` accepts these two new values with the same strict-sequence validation the existing ones already have (409 if called out of order).
- Two new `JobEventType` values (`en_route`, `passenger_on_board`) so they show up in the admin job-detail History timeline like every other transition.
- Two new "To admins" push notifications, same pattern as the existing `job_accepted`/`driver_arrived`/`job_completed` ones — suggested: `{type: "job_started", title: "Job started"}` and `{type: "passenger_on_board", title: "Passenger on board"}`, both carrying `job_id`, `driver_id`.

**Delivered and verified live, 26 Aug — exactly as suggested.** Confirmed directly, not just from the changelog:
- `JobStatus` now `pending_approval, open, accepted, en_route, arrived, passenger_on_board, completed, cancelled`; `JobEventType` gained matching `en_route`/`passenger_on_board` entries.
- Tested the skip-guard non-destructively first (`accepted → passenger_on_board` directly → 409), then ran a real job through the full sequence (`en_route → arrived → passenger_on_board → completed`) and confirmed all 4 events landed correctly in `GET /admin/jobs/:id/events`.
- Confirmed the one-active-job guarantee extends to the new states: created a second job and tried to accept it while the first was `en_route` → correctly blocked with 409.
- Confirmed `/jobs/:id/request-cancellation` still works from `en_route` (job released immediately, >2h out).
- Per the backend session's own note: `/admin/jobs/:id/reassign` and `/admin/jobs/:id/assign` were **not** extended to the two new states (still `accepted`-only / `open`+`accepted`-only) — flagged, not fixed blind. **Needs a decision from you:** should an admin be able to reassign a job that's already `en_route` or has `passenger_on_board`? If yes, that's a follow-up ask for the backend session.

**Client impact:** done — `active_job_view.dart` now shows all four steps in sequence (Start Job → Arrived to Pickup → Passenger On Board → Clear/Done, one button visible at a time, matching the confirmed status sequence exactly), the admin Accepted Jobs tab widened to `{accepted, en_route, arrived, passenger_on_board}` (kept together as one "trip in progress" view, per my own suggested default — flag if you'd rather split them), and `push_notification_service.dart` routes both new type codes (`job_started`, `passenger_on_board`) to the same Accepted tab as the existing `job_accepted`/`driver_arrived` ones.

## 11. Bottom-nav label overlap on narrow phones

**Found and fixed client-side, no backend involved** — the admin Jobs tab's 5-item bottom nav ("Website Jobs", "Active Jobs", "Accepted", "Completed", "Cancellations") wrapped and visually overlapped on narrow/low-resolution phones. Shortened the two long ones to "Website" and "Active" (the tab itself is already titled "Jobs", so dropping the repeated word reads fine).

## 12. `POST /push-tokens` rejects `platform: "web"`

**Confirmed live, 28 Aug:** a Firebase Web app is now registered (needed to make push notifications work on the web build at app.tsminicab.com, deployed the same day). The client now calls `/push-tokens` with `{"device_token": "...", "platform": "web"}` once a driver/admin logs in on web, same as it already does for `"ios"`/`"android"`. Tested directly against the real API with a real demo_driver JWT:

```
POST /api/push-tokens {"device_token": "...", "platform": "web"}
→ 400 {"error":"Validation failed","details":{"fieldErrors":{"platform":["Invalid enum value. Expected 'ios' | 'android', received 'web'"]}}}
```

So the endpoint has a strict enum validator (Zod, going by the error shape) that only accepts `ios`/`android` — `web` isn't in it at all. This isn't a crash on the client (AuthController's push-registration call is already wrapped in `.catchError`, same as any other push-token failure), but it means **no web device can ever register for push until this enum is widened** — every attempt just silently 400s forever.

**Needed:** add `"web"` to the accepted `platform` enum on this endpoint. No other shape change — the request body is otherwise identical to the existing ios/android case.

**Client impact:** none needed once this lands — already sending the right shape, just waiting on the enum to accept it.

**Confirmed fixed, 28 Aug** — re-ran the exact same live test with a fresh demo_driver JWT: `POST /api/push-tokens {"platform":"web",...}` now returns `201 {"message":"Push token registered"}`. Web push registration is fully live end-to-end.

**Confirmed end-to-end, 29 Aug** — real human test, not just an API check: logged in on `app.tsminicab.com` in a real browser, granted the notification permission prompt, backgrounded the tab, triggered a driver-facing push, and it actually arrived as a real browser notification. Web push is fully working, start to finish.

## 13. Auth endpoints have no rate limiting — exploitable, needs fixing before real launch

**Found in the pre-launch production audit, 29 Aug.** `POST /auth/login`, `/auth/driver/signup`, `/auth/driver/verify-otp`, and `/auth/request-password-reset` / `/auth/reset-password` all accept unlimited attempts — no lockout, no throttling. The OTP specifically is a 6-digit code, brute-forceable in a realistic number of requests with no rate limit in front of it. The sibling tsminicab.com site already has its own rate limiter (`lib/rateLimit.js`) — the dispatch API never got an equivalent.

**Needed:** rate-limit these endpoints — a per-IP and/or per-account attempt cap with a lockout/backoff window is the standard shape (exact numbers are your call; something like 5–10 attempts per 15 minutes per endpoint is a reasonable starting point). The OTP endpoint matters most given how brute-forceable a 6-digit code is without one.

**Client impact:** none expected — a 429 (or however you signal it) just needs to surface as a normal `ApiException` message, which the client already handles generically on every auth screen.

**User decision, 29 Aug:** fix this before the production data wipe (item 14) and before real store submission — flagged as the top priority alongside item 1's reopened decision.

**Confirmed live, 30 Aug** — per the backend session's report: login 10/15min, signup 5/60min, OTP verify 10/15min, password-reset request 5/60min, password-reset submit 10/15min. Verified by them hitting login 11 times: 10× 401, then a 429 with a proper `Retry-After` header. Not independently re-tested on this side (would mean locking out the demo account for real), but the shape matches what was asked for.

## 14. Production data: manual backups, and a data wipe once item 1's rework is tested

**Context:** pre-launch audit (29 Aug) found no automated backups and confirmed everything in the DB beyond `demo_admin`/`demo_driver` is test/QA debris (8 test accounts including one under the user's own personal email, 44 test jobs, 6 payments, 17 driver notes, 37 documents, 86 admin log entries, 7 cancellation requests) — full breakdown in the backend session's own audit report.

**Decided, 29 Aug:**
- **Backups: the user will handle this manually.** No automated backup setup needed from the backend session — noted so it doesn't get actioned as an open task.
- **Data wipe: authorized, but held.** Delete everything except `demo_admin`/`demo_driver` (which stay permanently — required App Store/Play reviewer accounts) once item 1's reworked overlap-based accept logic is built *and tested*. Do not delete before then — the client-side multi-active-job feature needs real data to test against first.

**Client impact:** none directly — this is a backend/DB action. Sequencing depends on item 1 and the client rework landing first.

**Condition met, 30 Aug** — item 1's rework is live and independently verified end-to-end (see item 1's own confirmation above), and item 13's rate limiting is also live. The wipe's stated precondition is satisfied; checking with the user for a final explicit go-ahead before it actually runs, given it's irreversible.

**Done, 30 Aug.** User gave explicit direct go-ahead (confirmed with both this session and the backend session separately, not just a relay). Ran in a single transaction with FK-safe delete order. Kept: `demo.admin@tsminicab.com` and `demo.driver@tsminicab.com`, nothing else.

| Table | Before | After |
|---|---|---|
| User | 10 | 2 |
| Driver | 8 | 1 |
| Vehicle | 5 | 1 |
| DriverDocument | 37 | 5 |
| DriverNote | 17 | 5 |
| Job | 47 | 0 |
| JobEvent | 209 | 0 |
| Payment | 6 | 0 |
| CancellationRequest | 7 | 0 |
| AdminActionLog | 89 | 74 |
| PushToken | 26 | 21 |
| OtpCode | 16 | 12 |

Independently re-verified live: `GET /health` → `{"status":"ok"}`, `demo_driver`'s `/jobs/mine` returns `[]`, `demo_admin`'s `/admin/drivers` returns exactly one driver (demo_driver). Item 14 closed.

---

## Already handled, no backend change needed

- **Fleet/vehicle class options** — confirmed live that `vehicle_class_requested` accepts any string, no server-side enum. Added "8-Seater Minibus" (was missing) to the client's dropdown to match the real 5-tier fleet (Saloon/Estate/Executive/MPV/8-Seater Minibus) with passenger/bag counts shown per option.
- **Paid/Unpaid semantics** — confirmed this already correctly means "has the admin paid the driver via wire transfer," not a customer-billing status. No change needed; this was built correctly in the last round.
- **CORS for the new web app** — checked live 26 Aug ahead of deploying `flutter build web` to a subdomain: the API already sends `Access-Control-Allow-Origin: *` (and allows the `authorization` header) on both preflight and real responses, for an unauthenticated route and an authenticated one. Nothing to change — the web app can call the API from any origin already. See `deploy/WEB_DEPLOY.md`.
