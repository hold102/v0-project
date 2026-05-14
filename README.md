# Expense Splitter

Expense Splitter is now structured as two apps:

```text
backend/   Node.js + Express API
frontend/  Flutter app
```

The old React and Next.js implementation has been removed.

## Backend

```bash
cd backend
npm install
npm run dev
```

The API defaults to `http://localhost:3000`.

Available routes:

- `GET /health`
- `GET /api/app-state`
- `POST /api/users`
- `POST /api/groups`
- `POST /api/expenses`
- `DELETE /api/expenses?groupId=...&expenseId=...`

Local JSON data is stored at `backend/data/app-db.json`. Override it with `APP_DB_PATH=/path/to/app-db.json`.

## Frontend

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

For web, choose a browser target when prompted by Flutter.

## Checks

From the repo root:

```bash
npm run check
```

Or run them separately:

```bash
npm --prefix backend run check
cd frontend && flutter analyze
cd frontend && flutter test
```
