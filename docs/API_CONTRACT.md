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

## Real response shapes (verified 2026-08-21 by calling the live API directly with curl/PowerShell, demo accounts)

The contract above describes routes; it never specified field names, so the client's first guesses (mostly snake_case, matching the contract's own request-body examples) were wrong for most GET responses, which turned out to be camelCase. This caused a real bug (driver detail 404s — `GET /admin/drivers` items have no `id` field, only `user_id`; the client was requesting `/admin/drivers/null`) and a would-be crash (`GET /payments/mine` returning `{paid: [...], unpaid: [...]}`, not a flat array). Documented here since none of this is guessable from the contract doc alone — needed live testing to find.

**`GET /admin/drivers?status=`** — list items:
```json
{"user_id":"...","email":"...","status":"active","role":"demo_driver","forename":"...","surname":"...","approval_status":"approved","vehicles":[...]}
```
`status` here is account active/inactive — unrelated to approval. The actual approval state is `approval_status` (`pending`/`approved`/`rejected`/`suspended` — the `?status=` query param filters on this despite the name; passing an account-status value like `active` 500s).

**`GET /admin/drivers/:id`** — same fields as above, plus: `dbs_check_date`, `phv_driver_licence_number`, `phone_number`, `approved_by`, `approved_at`, `bank_account_details` (a single free-text string, e.g. `"Sort code 12-34-56, Acc 12345678"` — not structured fields), `vehicles[]`, `documents[]`, `notes[]` (notes unconfirmed shape — none seeded).

**`GET /drivers/me`** — no `id`/`user_id` field at all. Has `theme_preference` (not `theme`), `has_bank_details` (boolean only, not the actual details), `dbs_check_date`, `phv_driver_licence_number`, `phone_number`, `approval_status`, `vehicles[]`. No `documents`/`notes` embedded (separate calls, matching the contract).

**Documents — inconsistent casing depending on which endpoint returns them** (confirmed, not a guess): embedded in `GET /admin/drivers/:id` → camelCase (`documentType`, `filePath`, `uploadedAt`, `verifiedByAdmin`, `expiryDate`). From `GET /drivers/me/documents` directly → snake_case (`document_type`, `uploaded_at`, `verified_by_admin`, `expiry_date`). Same underlying data, two different serializers. The client's `DriverDocument.fromJson` checks both. Neither shape includes a fetchable URL — `filePath`/`file_path` is a server filesystem path (e.g. `/var/lib/ts-minicab-dispatch/uploads/...`), not something the app can display or download directly. No document-view/download endpoint exists in the contract — flagged as a gap.

**`GET /jobs/open`, `GET /jobs/mine`, `GET /admin/jobs?status=`** — all camelCase: `id`, `source` (e.g. `"admin_manual"` — not documented as a concept anywhere in the original contract; likely how the website-jobs-queue distinguishes itself, replacing the client's original guess of a `pending_approval` status value, though no non-manual sample exists yet to confirm the exact string), `status`, `pickupDatetime`, `pickupAddress`, `dropoffAddress`, `customerName`, `customerContact`, `vehicleClassRequested` (every sample job has one — client now sends this on create, previously omitted it entirely), `fareAmount` (a **string**, e.g. `"65"`, not a number), `notes`, `currentDriverId` (id only, no accepted-driver name anywhere), `createdAt`, `createdBy`.

**`GET /payments/mine`** — NOT a flat list. Shape is `{"unpaid": [...], "paid": [...]}`, each entry: `id`, `jobId`, `driverId`, `amount` (string), `paidStatus` (`"paid"`/`"unpaid"` — not `status`), `paidAt`, `paidByAdminId`, `transactionSlipFilePath`, and a fully embedded `job` object (same shape as above). Genuinely useful — no manual cross-referencing against `/jobs/mine` needed.

**Admin has no equivalent payments endpoint.** `GET /admin/jobs?status=completed` returns identical data for a paid and an unpaid completed job (verified against the two seeded demo jobs — no payment field on the job object at all), and there's no `GET /admin/payments`. **The admin app cannot currently distinguish paid from unpaid completed jobs at all.** The Completed Jobs screen was changed from Paid/Unpaid tabs (which had no way to be populated correctly) to a single list with Mark Paid on every job. This needs either a payment-status field added to the admin job list, or a dedicated admin payments-list endpoint.

**`GET /admin/analytics`** — real fields: `total_jobs`, `completed_jobs`, `open_jobs`, `active_approved_drivers`, `total_revenue_paid`, `total_outstanding_unpaid`. No total-driver count, no week/month breakdowns (the contract doc's implied fields were invented, not real).

**Everything above was tested only via the `demo_admin`/`demo_driver` accounts** — POST endpoints that would mutate their seeded state (`/drivers/me/bank-details`, document upload field name) were deliberately not test-called to avoid corrupting the curated demo data, so those request-body shapes are still inferred (best-guess: matching the GET field names) rather than confirmed.
