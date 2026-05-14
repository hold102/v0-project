# Expense Splitter

Expense Splitter is now structured as two apps:

```text
backend/   Node.js + Express API
frontend/  Flutter app
```

The old React and Next.js implementation has been removed.

## First-time setup

1. Copy the env template and fill in your Supabase credentials:
   ```bash
   cp backend/.env.example backend/.env
   ```
   Set `SUPABASE_URL` and `SUPABASE_SECRET_KEY` from your Supabase dashboard (Project Settings -> API).
2. Apply the database schema. Either:
   - run `npm --prefix backend run migrate` (requires `DATABASE_URL` in `backend/.env`), **or**
   - open `backend/src/db/migrations/001_initial_schema.sql` and paste it into the Supabase SQL Editor.

## Backend

```bash
cd backend
npm install
npm run dev
```

The API listens on `http://localhost:5001` by default (override with `PORT` in `backend/.env`).

Available routes:

- `GET /health`
- `GET /api/app-state`
- `POST /api/users`
- `POST /api/groups`
- `POST /api/expenses`
- `DELETE /api/expenses?groupId=...&expenseId=...`

Data is persisted in Supabase Postgres via the tables and `sync_full_database` stored procedure created by the migration above.

## Frontend

```bash
cd frontend
flutter pub get
flutter run
```

The API base URL is resolved automatically per platform (localhost on iOS/desktop, `10.0.2.2` on the Android emulator). To override it at build time:

```bash
# Full override (use any reachable backend)
flutter run --dart-define=API_BASE_URL=http://localhost:5001/api

# Or just the LAN IP, for testing the web build from a phone on the same network
flutter run --dart-define=API_HOST_IP=192.168.1.42
```

For web, choose a browser target when prompted by Flutter.

## Docker (backend only)

```bash
docker compose up --build
```

The compose file builds `backend/Dockerfile` and reads secrets from `backend/.env`. The Flutter frontend is not containerized — it builds for mobile/desktop/web targets directly via the `flutter` CLI.

## CI

GitHub Actions workflow at `.github/workflows/ci.yml` runs on every push and PR to `main`:

- **Backend** — `npm ci`, `npm run check`, `npm test`
- **Frontend** — `flutter pub get`, `flutter analyze`, `flutter test`

## Checks

From the repo root:

```bash
npm run check
```

Or run them separately:

```bash
npm --prefix backend run check
npm --prefix backend test
cd frontend && flutter analyze
cd frontend && flutter test
```
