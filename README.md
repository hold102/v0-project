# SplitEase

A mobile-friendly expense splitting app built with Flutter + Node.js + Supabase.

---

## Prerequisites

- [Node.js 20+](https://nodejs.org)
- [Flutter 3+](https://flutter.dev/docs/get-started/install)
- A [Supabase](https://supabase.com) project
- A [Brevo](https://brevo.com) account (for email verification)

---

## 1. Database Setup

1. Open your Supabase project → **SQL Editor**
2. Run `backend/src/db/migrations/001_initial_schema.sql`
3. Run `backend/src/db/migrations/002_split_amounts.sql`

---

## 2. Backend Setup

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

Fill in `backend/.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SECRET_KEY=your-service-role-key
JWT_SECRET=any-random-secret-string
BREVO_API_KEY=your-brevo-api-key
APP_BASE_URL=http://localhost:5001
PORT=5001
```

- `SUPABASE_URL` and `SUPABASE_SECRET_KEY` → Supabase dashboard → Project Settings → API
- `BREVO_API_KEY` → Brevo dashboard → SMTP & API → API Keys
- `APP_BASE_URL` → the public URL of your backend (use `http://localhost:5001` for local dev)

The API will be running at `http://localhost:5001`.

---

## 3. Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

To point the app at a specific backend URL:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:5001/api
```

For web:

```bash
flutter build web
# Output is in frontend/build/web/
```

---

## 4. Cloud Deployment

### Backend → Render

1. Push your repo to GitHub
2. Go to [render.com](https://render.com) → New → Web Service
3. Connect your repo, set **Root Directory** to `backend`, **Environment** to `Docker`
4. Add all environment variables from `.env` (use your Render URL for `APP_BASE_URL`)

### Frontend → Netlify

1. Update `API_BASE_URL` in the Flutter app to your Render backend URL
2. Run `flutter build web`
3. Drag the `frontend/build/web/` folder to [netlify.com](https://netlify.com)

---

## 5. Running Tests

```bash
# Backend
npm --prefix backend test

# Frontend
cd frontend && flutter test
```
