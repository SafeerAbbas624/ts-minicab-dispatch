# Deploying the web app to the VPS

Same VPS that already runs the backend and tsminicab.com — this just adds a
second nginx server block for a new subdomain, serving a static build. It
doesn't touch the backend's own nginx config or process.

## 1. Pick the subdomain and add the DNS record

Any name works — `app.tsminicab.com` and `admin.tsminicab.com` are the two
obvious choices (the same web build serves both admin and driver panels, so
either name fits; driver-facing use is expected to stay mostly on the native
apps). Whatever you pick:

| Type | Name                          | Value                         |
|------|-------------------------------|--------------------------------|
| A    | `app` (or your chosen prefix) | your VPS's IP address (same one `tsminicab.com`'s own A record already points to) |

Add that at wherever tsminicab.com's DNS is managed. No CNAME needed since
you're pointing straight at the VPS — a straightforward A record. DNS
propagation is usually minutes, occasionally up to ~an hour depending on
your registrar/DNS provider.

## 2. Build the production bundle (done on your dev machine, this repo)

```
flutter build web --release
```

Output lands in `build/web/` — everything in there is static (HTML/JS/CSS/
assets), no server-side rendering, no Node process to run for the web app
itself.

## 3. Copy the build to the VPS

From your dev machine:

```
scp -r build/web/* user@your-vps-ip:/var/www/ts-minicab-web/
```

(Create `/var/www/ts-minicab-web/` on the VPS first if it doesn't exist —
`mkdir -p /var/www/ts-minicab-web`.)

## 4. Add the nginx server block

Copy `deploy/nginx-web.conf` from this repo to the VPS (e.g.
`/etc/nginx/sites-available/ts-minicab-web`), replace `WEBAPP_SUBDOMAIN` in
it with your actual chosen subdomain, then:

```
ln -s /etc/nginx/sites-available/ts-minicab-web /etc/nginx/sites-enabled/
nginx -t          # test the config before reloading
systemctl reload nginx
```

(Adjust paths if your VPS doesn't use the sites-available/sites-enabled
convention — some setups just drop `.conf` files straight into
`/etc/nginx/conf.d/`.)

## 5. Get HTTPS on it

Once the DNS record has propagated (`dig app.tsminicab.com` should return
your VPS's IP), run certbot for the new subdomain — this rewrites the nginx
block to add the SSL cert paths and a port-443 server block automatically:

```
certbot --nginx -d app.tsminicab.com
```

(Substitute your actual subdomain.) If certbot isn't already installed,
that's the same tool likely already used for tsminicab.com and the API's own
HTTPS — check `certbot certificates` to confirm before installing again.

## 6. Backend CORS — already fine, no change needed

Checked live before writing this doc: the API already sends
`Access-Control-Allow-Origin: *` (and allows the `authorization` header) on
both the preflight and the real response, for both an unauthenticated route
(`/auth/login`) and an authenticated one (`/admin/jobs`). The web app can
talk to `https://api.tsminicab.com` from any subdomain with zero backend
changes.

## Redeploying after a future change

Repeat steps 2–3 only (build, then `scp` over the old files) — nginx and DNS
stay as they are once set up once.

## Rollback

Keep the previous `build/web/` output around (e.g. rename to
`build/web-YYYYMMDD/` before overwriting) if you want a quick way back —
copying the old folder's contents back over `/var/www/ts-minicab-web/` and
reloading nginx (`systemctl reload nginx`) is enough, no rebuild needed.
