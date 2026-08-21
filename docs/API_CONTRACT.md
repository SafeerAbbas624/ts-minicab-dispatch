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
