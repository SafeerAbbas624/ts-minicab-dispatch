# Backend requests — feature round, 24 Aug 2026

Everything below is needed to finish the feature list requested on this date. Each item says what's missing, why, and a suggested shape — the backend session should treat the suggested shape as a starting point, not a spec set in stone. Client-side work that depends on each item is noted so priority can be judged.

**Status, 25 Aug 2026: all 6 items delivered and live. Client-side wiring for all of them is done and live-verified against the real API on the emulator — see the "Delivered" / "Client impact" note on each item below. One open bug remains: item 5's `penalize: false` flag is not respected server-side (see that section).**

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

**Client impact:** built and live-verified — the driver picker (name/email search) now calls the real `/assign` endpoint. Wired into both the Accepted Jobs tab's "Reassign" (with "Reopen to general pool" still pinned at the top) and the Active Jobs tab's new "Assign to driver" action, confirmed `/assign` works from `open` status too. `GET /admin/drivers` still doesn't return a phone number, so search only matches name/email — if phone-number search matters, that field still needs adding to the list response.

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
- **Bug found in live testing:** `penalize: false` on the approve endpoint still logs a penalty note on the driver's record — same behavior as `penalize: true`. Tested twice with fresh requests to rule out a fluke. The client now sends the flag correctly and shows a warning about this in the approve dialog, but the toggle currently has no effect server-side. Needs a fix so `penalize: false` skips writing the driver note.

**Client impact:** built and live-verified — driver-side warning dialog (copy below) wired to `request-cancellation`, a "Pending cancellation" banner that disables the active-job actions, and an admin Cancellations inbox tab with Approve/Reject.

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

---

## Already handled, no backend change needed

- **Fleet/vehicle class options** — confirmed live that `vehicle_class_requested` accepts any string, no server-side enum. Added "8-Seater Minibus" (was missing) to the client's dropdown to match the real 5-tier fleet (Saloon/Estate/Executive/MPV/8-Seater Minibus) with passenger/bag counts shown per option.
- **Paid/Unpaid semantics** — confirmed this already correctly means "has the admin paid the driver via wire transfer," not a customer-billing status. No change needed; this was built correctly in the last round.
