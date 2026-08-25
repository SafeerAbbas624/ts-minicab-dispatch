# Backend requests — feature round, 24 Aug 2026

Everything below is needed to finish the feature list requested on this date. Each item says what's missing, why, and a suggested shape — the backend session should treat the suggested shape as a starting point, not a spec set in stone. Client-side work that depends on each item is noted so priority can be judged.

**Status, 26 Aug 2026: everything through item 9 is closed out.** All 6 original items delivered and live, client-side wiring done and live-verified. The two item 5 follow-up bugs (`penalize: false`, review-note field-name mismatch) are fixed and re-verified live; item 4's phone-number gap is fixed; item 7 (`POST /push-tokens` 403 for admins) is fixed. Item 8 is decided (Option C — see below); item 9's `data.type` payload is delivered, verified live end-to-end, and the client now routes on it instead of matching title text. Item 10 (two new job-status steps, Start Job/Passenger On Board, with notifications) is delivered, live-verified, and fully wired client-side. Item 11 was a client-only fix, no backend involved. **Open decision (not a bug):** should admin reassign/assign extend to the two new mid-trip states — see item 10's note.

## 1. Prevent a driver from holding more than one active job at once

**Confirmed live, reproducible every time:** `POST /jobs/:id/accept` currently lets the same driver accept any number of jobs simultaneously, even ones that overlap in time. Tested by creating two jobs (pickup 3h and 6h out) and accepting both back-to-back as the same driver — both succeeded, no 409, no rejection at all.

**Needed:** before accepting, reject with 409 if the driver already has a job in `accepted` or `arrived` status. Recommended: block on *any* existing active job, not just time-overlapping ones — simplest to implement, and safest from a dispatch-integrity standpoint (a driver mid-job accepting a same-day job "for later" is exactly the kind of thing that goes wrong when the first job runs long). If sequential non-overlapping jobs should be allowed instead (driver 1 holds an 8am, 11am, and 2pm job simultaneously), that needs a time-window overlap check instead of a flat one-active-job rule — worth deciding explicitly rather than defaulting to it.

**Client impact:** none needed once this lands — the driver app already only shows one "active job" slot in its UI; it just isn't backed by a server-side guarantee yet.

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

---

## Already handled, no backend change needed

- **Fleet/vehicle class options** — confirmed live that `vehicle_class_requested` accepts any string, no server-side enum. Added "8-Seater Minibus" (was missing) to the client's dropdown to match the real 5-tier fleet (Saloon/Estate/Executive/MPV/8-Seater Minibus) with passenger/bag counts shown per option.
- **Paid/Unpaid semantics** — confirmed this already correctly means "has the admin paid the driver via wire transfer," not a customer-billing status. No change needed; this was built correctly in the last round.
