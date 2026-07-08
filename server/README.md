# Arise API (Railway)

Tiny Node/Express backend that gives the PWA cloud sync with **Google sign-in**
and **Railway Postgres**. Deployed straight from this GitHub repo — Railway
watches the repo and redeploys on every push. No Railway API access needed.

```
PWA (GitHub Pages)  ──►  this API (Railway)  ──►  Postgres (Railway)
```

## Endpoints
- `GET  /health` — health check.
- `POST /api/auth/google` `{ idToken }` → verifies the Google ID token, upserts
  the user, returns `{ token, user }` (a 60-day session JWT).
- `GET  /api/state` (Bearer token) → `{ state, updatedAt }`.
- `PUT  /api/state` (Bearer token) `{ state }` → upserts, returns `{ updatedAt }`.

Tables (`users`, `user_state`) are created automatically on boot.

## Deploy on Railway (one time)
1. **railway.com → New Project → Deploy from GitHub repo** → pick this repo.
2. On the service → **Settings → Root Directory = `server`** (this folder).
3. **New → Database → Add PostgreSQL** in the same project.
4. Service → **Variables**:
   - `DATABASE_URL` → reference the Postgres: value `${{Postgres.DATABASE_URL}}`
   - `GOOGLE_CLIENT_ID` → your Google OAuth **Web** client ID
   - `JWT_SECRET` → a long random string
   - `CORS_ORIGIN` → `https://virgax.github.io`
5. Railway builds and gives you a public URL like `https://arise-api.up.railway.app`.
   Check `GET /health` returns `{ "ok": true }`.

Then set the PWA's `VITE_API_URL` to that URL (GitHub → repo Variables) and the
web app will sync through it.

## Google OAuth client (for sign-in)
Google Cloud Console → APIs & Services → Credentials → **Create OAuth client ID
→ Web application**. Add your Pages origin (`https://virgax.github.io`) to
**Authorized JavaScript origins**. Use the resulting **Client ID** both here
(`GOOGLE_CLIENT_ID`) and in the PWA (`VITE_GOOGLE_CLIENT_ID`).
