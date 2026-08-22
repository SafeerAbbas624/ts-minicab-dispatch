# TS Minicab API Contract

This is the fixed contract between the Flutter app (this repo) and the backend
(built by a separate Claude Code session on the company VPS). Do not invent or
guess alternative endpoint shapes — if the live backend's response doesn't
match this doc, that's a mismatch to reconcile between the two sessions, not
something to silently work around in the client.

Base URL: `https://api.tsminicab.com` (configurable at build time via
`--dart-define=API_BASE_URL=...`)

All routes are prefixed `/api` on the base URL. Send `Authorization: Bearer <JWT>`
on every route except signup/login/OTP.

## Auth & account

- `POST /auth/driver/signup` — `{email, password, forename, surname, phone_number}` → triggers OTP email
- `POST /auth/driver/verify-otp` — `{email, otp}`
- `POST /auth/login` — `{email, password}` → `{token, role}`
- `POST /auth/request-password-reset` — `{email}`
- `POST /auth/reset-password` — `{token, new_password}`
- `POST /account/delete-request` — auth required

## Driver-facing (role: driver, demo_driver)

- `GET /drivers/me`
- `PATCH /drivers/me` — theme/avatar/password only
- `POST /drivers/me/bank-details`
- `POST /drivers/me/documents` — multipart
- `GET /drivers/me/documents`
- `GET /jobs/open` — sorted `pickup_datetime` ascending
- `POST /jobs/:id/accept` — handle 409 ("already taken") explicitly in the UI
- `POST /jobs/:id/release` — `{reason}`
- `POST /jobs/:id/status` — `{status: arrived|completed}`
- `GET /jobs/mine`
- `GET /payments/mine`
- `POST /push-tokens` — `{device_token, platform}` — call right after login and whenever the FCM token refreshes

## Admin-facing (role: admin, super_admin, demo_admin)

- `GET /admin/drivers?status=`
- `GET /admin/drivers/:id`
- `POST /admin/drivers/:id/approve`
- `POST /admin/drivers/:id/reject`
- `POST /admin/drivers/:id/suspend`
- `DELETE /admin/drivers/:id` — only show this action if the logged-in role is super_admin
- `POST /admin/drivers/:id/notes` — `{note_text}`
- `POST /admin/admins` — `{email, password}` — super_admin only
- `DELETE /admin/admins/:id` — super_admin only
- `POST /admin/jobs`
- `GET /admin/jobs?status=`
- `PATCH /admin/jobs/:id`
- `POST /admin/jobs/:id/approve`
- `POST /admin/jobs/:id/cancel` — `{reason}`
- `POST /admin/jobs/:id/reassign`
- `POST /admin/payments/:job_id/mark-paid` — multipart, `transaction_slip` optional
- `GET /admin/analytics`
- `GET /admin/tfl-export?week_start=`
- `GET /admin/tfl-export/csv?week_start=` — trigger a download/share of this
- `GET /admin/action-log`

## Roles

- Admin-family (`admin`, `super_admin`, `demo_admin`) → Admin panel
- Driver-family (`driver`, `demo_driver`) → Driver panel
- `demo_admin`/`demo_driver` behave identically to real accounts — full feature access, for App Store/Play reviewers

## Explicit non-goals

No maps/location SDK, no in-app payments, no direct DB access, no flight tracking, no social login.

## Reconciliation notes (from the backend session, 2026-08-21)

These correct or firm up assumptions made on the Flutter side before the backend confirmed behavior:

- **Base URL is confirmed**: `https://api.tsminicab.com/api` for all documented routes. `/internal/*` routes are backend-to-backend only — never call them from the app.
- **401 vs 403 are different signals**: 401 = dead/invalid token → force logout back to login (handled globally in the dio interceptor). 403 = valid token, wrong role/status (e.g. driver not yet approved, suspended) → show the message from the response body, do **not** log the user out.
- **Driver approval is NOT a field on the session or on `GET /drivers/me`** — the backend signals "not approved yet" by returning 403 on job-related endpoints (e.g. `GET /jobs/open`) with a message like "Driver account is not approved". The app treats this as a distinct pending-approval UI state, gated on that 403 rather than on a status field. (This reverses the assumption in the very first milestone report — `GET /drivers/me`'s response shape for a `status` field is still unconfirmed and no longer load-bearing for routing.)
- **Signup flow confirmed as built**: signup → OTP verify → separate login (verify-otp does not auto-authenticate).
- **Upload constraints**: PDF/JPEG/PNG/WEBP only, 10MB max, enforced client-side before upload (backend 400s otherwise) — applies to `/drivers/me/documents` and `/admin/payments/:job_id/mark-paid`.
- **409 on `/jobs/:id/accept` is expected, not an error** — confirmed as built (refresh list, show "already taken").
- **Push notifications**: Firebase project `ts-mincab` exists; Android/iOS apps and their config files (`google-services.json` / `GoogleService-Info.plist`) still need to be created in the Firebase console and handed over before the native side can be wired up. `POST /push-tokens` is documented only under the driver section, but the spec calls for admin push too (website-job-needs-approval alerts) — flagged as unresolved; the Dart-side service is written role-agnostic to cover both once confirmed.

## Authoritative field-level reference (2026-08-22)

The backend session published a full API reference generated directly from its live route source code (not hand-written docs) — treat it as the source of truth for field names/casing over everything below, including the "verified by live testing" notes further down, which got a couple of things wrong by inference. Key points, since the reference itself isn't checked into this repo:

- **Casing is genuinely inconsistent by design, not by accident**: hand-shaped responses (auth, driver profile, admin driver list/detail) are `snake_case`. Anything that's a raw Prisma row (`Job`, `Vehicle`, `Payment`, `JobEvent`, `DriverNote`, `AdminActionLog`) is `camelCase`. **Job/admin-job POST and PATCH request bodies are `snake_case`** even though the matching GET response is `camelCase` — this is a real, intentional asymmetry (confirmed by test-creating and then cancelling a real job against the live API). Decimal fields (`fareAmount`, `amount`) always serialize as JSON strings on the way out, but `POST /admin/jobs`'s `fare_amount` accepts a plain number.
- **`DriverApprovalStatus` is only `pending | approved | rejected`** — there is no "suspended" approval status. Suspension is a separate `UserStatus` concept (`active | suspended | deletion_requested`) tracked on the same `status` field that also means "account active/inactive" elsewhere. A driver can be `approval_status: approved` and `status: suspended` simultaneously. `GET /admin/drivers?status=` only filters on approval status (`pending|approved|rejected`) — there's no way to filter the list by account status.
- **`JobStatus` enum**: `pending_approval | open | accepted | arrived | completed | cancelled`. Website-sourced jobs start at `pending_approval`; admin-created jobs skip straight to `open` (confirmed live). `POST .../approve` does `pending_approval → open`. So the Website Jobs Queue filters `GET /admin/jobs?status=pending_approval` directly — no need to fetch everything and filter by `source` client-side.
- **`JobSource` enum**: `website | admin_manual`.
- **`DocumentType` enum**: `phv_licence | insurance | dbs | mot | other`.
- **Avatar has no upload endpoint at all.** `PATCH /drivers/me` only accepts `avatar_url` as a plain string (plus `theme_preference`, `password`) — there is no multipart file-upload route for avatars anywhere in the API. The driver Settings screen sets a URL directly rather than picking a local image file; this is a real capability limit of the backend, not a client shortcut.
- **`POST /admin/jobs/:id/reassign` takes no body** — it just unassigns the current driver (`accepted → open`, clears `currentDriverId`); it doesn't target a specific replacement driver despite the name.
- **Error shape is always `{"error": "..."}`**, never `{"message": "..."}`. Zod validation failures add `details.fieldErrors`, which the client now appends to the error message shown to the user.
- **`GET /admin/drivers/:id`'s `bank_account_details` is decrypted plaintext** for admin/super_admin — "never expose this screen to a non-admin" per the reference (already true; it's admin-only in the app). The driver's own `POST /drivers/me/bank-details` stores it encrypted; `GET /drivers/me` only ever returns a `has_bank_details` boolean, never the value back.
- **`POST /drivers/me/documents` accepts an optional `expiry_date`** alongside `file` and `document_type` — now sent when the user provides one is wired up in the repository, though no UI control for it was added yet (contract only calls for "per-document status," expiry wasn't in the original screen list).
- Timestamps sent to the API should be UTC (`Z` suffix) — date/time pickers produce local time, so the client converts with `.toUtc()` before serializing.

## Real response shapes (verified 2026-08-21 by calling the live API directly with curl/PowerShell, demo accounts)

Superseded by the authoritative reference above wherever they conflict (the `pending_approval`-vs-`source` filter and the job create/update body casing are the two places this session's inference turned out wrong). Kept for the parts that still add detail the reference doesn't spell out — exact sample payloads and the confirmed-gap findings below.

**`GET /admin/drivers?status=`** — list items:
```json
{"user_id":"...","email":"...","status":"active","role":"demo_driver","forename":"...","surname":"...","approval_status":"approved","vehicles":[...]}
```

**`GET /admin/drivers/:id`** — same fields as above, plus: `dbs_check_date`, `phv_driver_licence_number`, `phone_number`, `approved_by`, `approved_at`, `bank_account_details` (a single free-text string, e.g. `"Sort code 12-34-56, Acc 12345678"`), `vehicles[]`, `documents[]`, `notes[]` (notes unconfirmed shape — none seeded).

**`GET /drivers/me`** — no `id`/`user_id` field at all (per the authoritative reference, the driver's id is the JWT's `sub` claim instead). Has `theme_preference`, `has_bank_details` (boolean only), `dbs_check_date`, `phv_driver_licence_number`, `phone_number`, `approval_status`, `vehicles[]`.

**Documents — inconsistent casing depending on which endpoint returns them**: embedded in `GET /admin/drivers/:id` → camelCase (`documentType`, `filePath`, `uploadedAt`, `verifiedByAdmin`, `expiryDate`). From `GET /drivers/me/documents` directly → snake_case (`document_type`, `uploaded_at`, `verified_by_admin`, `expiry_date`). Same underlying data, two different serializers — the client's `DriverDocument.fromJson` checks both. Neither shape includes a fetchable URL — `filePath`/`file_path` is a server filesystem path, not something the app can display or download. No document-view/download endpoint exists — flagged as a gap.

**`GET /payments/mine`** — NOT a flat list. Shape is `{"unpaid": [...], "paid": [...]}`, each entry with a fully embedded `job` object. No manual cross-referencing against `/jobs/mine` needed.

**`GET /admin/analytics`** — real fields: `total_jobs`, `completed_jobs`, `open_jobs`, `active_approved_drivers`, `total_revenue_paid`, `total_outstanding_unpaid`.

## Backend bug-fix pass (2026-08-23) — supersedes several items above

Five issues found during a client-side audit were fixed and verified live against the real API. **This section overrides the corresponding claims above** rather than editing them in place, so the history of what changed stays visible:

- **Decimal fields are now plain JSON numbers everywhere**, not strings — `fareAmount`, `amount`, `total_revenue_paid`, `total_outstanding_unpaid` included. A response middleware normalizes Prisma's Decimal type centrally, so this covers every current and future money field, not just the ones enumerated above. The client still parses defensively (`num` or numeric string) in case an older backend build is ever hit, but no longer assumes strings.
- **`GET /admin/payments` now exists** (`?status=paid|unpaid`, omit for all) — a dedicated payments-first view, each row nesting the full `job` and a trimmed `driver` (`forename`, `surname`, `phvDriverLicenceNumber`). Also, every admin-facing `Job` response (list/create/edit/approve/reassign) now nests a `payment` object (or `null`) directly on the job. The "admin has no equivalent payments endpoint" gap noted above is resolved — the admin app's Payments screen now uses `GET /admin/payments?status=unpaid`.
- **Driver notes now carry their author.** `GET /admin/drivers/:id` and `POST /admin/drivers/:id/notes` nest `admin: {email, role}` on every `DriverNote`, same shape the action log already used. Previously there was no author field at all.
- **Action log entries now carry ready-made `description` and `target_label` fields**, resolved server-side (batch-fetched, not N+1) — e.g. `description: "demo.admin@tsminicab.com approved driver Pending Applicant"`. Falls back to `"deleted driver (a1b2c3d4)"`-style text if the target was since deleted. The client still humanizes `actionType`/`note` as a fallback if `description` is ever absent, but no longer needs to build it as the primary path.
- **`POST /auth/request-password-reset` no longer 500s for real accounts.** Root cause: `demo.admin@tsminicab.com`/`demo.driver@tsminicab.com` aren't provisioned mailboxes, so SMTP rejected the send with `550 Mailbox does not exist`, and the send call wasn't wrapped in try/catch — it threw all the way up to a 500. Fixed in both password-reset and signup (signup now rolls back the half-created account and returns a clear error instead of leaving it stuck). Verified: 200, not 500, for both demo accounts.
