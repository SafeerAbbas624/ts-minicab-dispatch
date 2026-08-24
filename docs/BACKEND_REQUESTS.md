# Backend requests — feature round, 24 Aug 2026

Everything below is needed to finish the feature list requested on this date. Each item says what's missing, why, and a suggested shape — the backend session should treat the suggested shape as a starting point, not a spec set in stone. Client-side work that depends on each item is noted so priority can be judged.

## 1. Prevent a driver from holding more than one active job at once

**Confirmed live, reproducible every time:** `POST /jobs/:id/accept` currently lets the same driver accept any number of jobs simultaneously, even ones that overlap in time. Tested by creating two jobs (pickup 3h and 6h out) and accepting both back-to-back as the same driver — both succeeded, no 409, no rejection at all.

**Needed:** before accepting, reject with 409 if the driver already has a job in `accepted` or `arrived` status. Recommended: block on *any* existing active job, not just time-overlapping ones — simplest to implement, and safest from a dispatch-integrity standpoint (a driver mid-job accepting a same-day job "for later" is exactly the kind of thing that goes wrong when the first job runs long). If sequential non-overlapping jobs should be allowed instead (driver 1 holds an 8am, 11am, and 2pm job simultaneously), that needs a time-window overlap check instead of a flat one-active-job rule — worth deciding explicitly rather than defaulting to it.

**Client impact:** none needed once this lands — the driver app already only shows one "active job" slot in its UI; it just isn't backed by a server-side guarantee yet.

## 2. Document viewing and verification for admins

**Confirmed via the earlier API reference reconciliation:** `file_path`/`filePath` on a document record is a server filesystem path, not anything the app can load. There is no endpoint that serves the actual file content, and no endpoint that lets an admin mark a document verified or rejected — `verified_by_admin`/`verified_at` exist as fields but nothing ever sets them from the admin side today.

**Needed:**
- A way to fetch the actual file — either `GET /admin/drivers/:driver_id/documents/:document_id/file` streaming the raw bytes, or the document list response switching to a signed/temporary URL the app can load directly (`Image.network`/PDF viewer). Same gap exists driver-side for the driver's own documents, if drivers should be able to review what they uploaded.
- `POST /admin/drivers/:driver_id/documents/:document_id/verify` and a reject counterpart (with a reason, mirroring how job cancellation already asks for one) — sets `verified_by_admin`/`verified_at`.

**Client impact:** once these exist, I'll build the admin document-review screen (list with thumbnails/preview, Verify/Reject actions) and a driver-side "view what I uploaded" screen.

## 3. New document types

Current `DocumentType` enum: `phv_licence | insurance | dbs | mot | other`. Requested additions: driver's licence, car (vehicle) picture, driver's own photo, and something covering the TfL PCO badge.

**One thing to confirm before adding these:** is the TfL PCO badge a **document to upload** (a photo of the physical badge) like the others, or a **text field** on the driver's profile (the badge number itself), or both? The request as written ("TFL BADGE DRIVER number PCO") reads like it could be either — worth deciding since a text field is a very different (much smaller) change than a new document type.

**Needed (assuming upload):** add enum values, e.g. `driving_licence`, `vehicle_photo`, `driver_photo`, `tfl_badge` — exact names up to whoever owns the schema, the client just needs to know what they are.

**Client impact:** once the enum values are confirmed, I'll add them to the driver's document-type picker and the admin verification screen from item 2.

## 4. Direct driver reassignment

**Confirmed via the API reference and live testing:** `POST /admin/jobs/:id/reassign` only unassigns the current driver (`accepted → open`, clears `currentDriverId`) — it reopens the job to the general pool for any approved driver to self-accept. There's no way for an admin to assign a job directly to a *specific* driver; only a driver's own authenticated accept call can do that today.

**Needed:** a new endpoint, e.g. `POST /admin/jobs/:id/assign` with `{"driver_id": "..."}` — sets `currentDriverId` and status directly (bypassing the normal self-service accept race), presumably validating the target driver is `approved`/`active`. Whether the existing reassign-to-pool behavior should stay as a separate action or be replaced entirely by "reassign always means pick a specific driver" is a product call — the client can support either.

**Client impact:** the driver-search/picker UI itself needs no backend gap to build (the existing `GET /admin/drivers?status=approved` already returns everything needed for a searchable list) — only the actual "assign to this driver" action needs the new endpoint.

## 5. Cancellation-request/approval workflow with a 2-hour cutoff

This is the biggest new piece — a genuinely new workflow, not an extension of an existing one.

**Requested behavior:**
- More than 2 hours before pickup: a driver can cancel an accepted job immediately, same as today (`POST /jobs/:id/release`).
- Less than 2 hours before pickup: the driver can no longer cancel outright. Instead they submit a cancellation **request** with a required reason. The job stays assigned to them, shown as "pending cancellation," until an admin reviews it.
- Admin reviews the request: if approved, the job is actually released/reopened and the driver is penalized (mechanism TBD — see below). If not approved, the job simply stays assigned as normal — nothing changes.

**Needed:**
- A way to represent "pending cancellation" — either a new `JobStatus` value or a boolean flag alongside the existing status, plus a place to store the driver's reason text and the timestamp.
- `POST /jobs/:id/request-cancellation` (driver) — body `{"reason": "..."}`. Should 409 if the job isn't `accepted`/`arrived`, and probably only make sense to call when under the 2-hour mark (calling it when there's more than 2 hours left could just be routed straight to the existing immediate-release path instead, client-side or server-side — worth deciding which).
- `GET /admin/cancellation-requests` (or filter into the existing jobs list) — so admins can see what's pending.
- `POST /admin/cancellation-requests/:id/approve` — releases the job and applies the penalty.
- `POST /admin/cancellation-requests/:id/reject` — dismisses the request, job stays assigned, driver sees it's no longer pending.

**Needs a decision, not just an implementation:** what "penalized" actually means. A strike count on the driver record? A note logged automatically (reusing the existing driver-notes mechanism)? Something that affects future job eligibility? The client can display and act on whatever gets decided — it just needs the concept to exist somewhere it can read from.

**Client impact:** driver-side, I've already drafted the professional-tone copy for the warning dialog (below) — ready to wire in once the endpoints exist. Admin-side, a pending-cancellations list/inbox with approve/reject actions.

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

**Client impact:** the popup currently only shows the job's *current* status — I didn't build a fake timeline against data that doesn't exist. Once this endpoint exists, I'll extend the popup with a proper history section.

---

## Already handled, no backend change needed

- **Fleet/vehicle class options** — confirmed live that `vehicle_class_requested` accepts any string, no server-side enum. Added "8-Seater Minibus" (was missing) to the client's dropdown to match the real 5-tier fleet (Saloon/Estate/Executive/MPV/8-Seater Minibus) with passenger/bag counts shown per option.
- **Paid/Unpaid semantics** — confirmed this already correctly means "has the admin paid the driver via wire transfer," not a customer-billing status. No change needed; this was built correctly in the last round.
