# ImYoVo100 — 1,000 English Words in 100 Days

Production-oriented Next.js + Supabase web app for a locked 100-day vocabulary journey.

## Stack

- Next.js 16 App Router + React 19 + TypeScript
- Supabase Auth + Postgres + Row Level Security + RPC
- Plain CSS (no Tailwind/PostCSS dependency)
- Vercel deployment

## What is implemented

- Email/password sign-up, sign-in, confirmation callback, sign-out
- Password reset flow with PKCE callback
- SSR cookie sessions with `@supabase/ssr` and Next.js `proxy.ts`
- 8 learner segments: preschool, primary, THCS, THPT, university, postgraduate, working adults, seniors
- 100-day time-gated roadmap
- 10 words/day segmented curriculum
- Flashcards + daily quiz
- Quiz scoring inside Postgres RPC (browser cannot self-report correctness)
- Study history and progress
- Spaced-repetition review queue
- Admin curriculum import through an atomic, role-checked database RPC
- RLS blocks future lesson vocabulary at the Data API layer
- `/api/health` checks live Supabase Auth connectivity without exposing secrets
- GitHub Actions: typecheck + lint + production build

## 1. Supabase setup

Create a Supabase project, then open **SQL Editor** and run these files in order:

1. `supabase/schema.sql`
2. `supabase/seed.sql` (optional smoke-test content for Day 1)
3. `supabase/verify.sql` (verification; every row should be `PASS`)

The schema creates the course and all 100 lesson shells automatically.

### Make the first account an admin

Register the account normally first. Then run this once in Supabase SQL Editor, replacing the email:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and u.email = 'YOUR_EMAIL@example.com';
```

Users cannot promote themselves through the public API because profiles have no client update policy.

## 2. Environment variables

Copy `.env.example` to `.env.local`:

```bash
cp .env.example .env.local
```

Required:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

For older projects, `NEXT_PUBLIC_SUPABASE_ANON_KEY` is supported as a fallback to the publishable key.

Do **not** add a Supabase service-role key to this app. It is not needed.

Run configuration checks:

```bash
npm run check:env
npm run check:supabase
```

`check:supabase` calls the official Supabase Auth health endpoint and fails clearly if URL/key/network is wrong.

## 3. Supabase Auth URL configuration

In **Supabase → Authentication → URL Configuration**:

### Local

- Site URL: `http://localhost:3000`
- Redirect URL: `http://localhost:3000/**`

### Production

Set Site URL to the canonical Vercel/custom domain, e.g.:

- `https://imyovo100.vercel.app`

Add an exact production redirect URL:

- `https://imyovo100.vercel.app/**`

If Vercel Preview deployments need auth, add the appropriate Vercel preview wildcard for your team/account as documented by Supabase.

The application uses these callback routes:

- `/auth/callback` — email confirmation + PKCE exchange
- `/auth/callback?next=/auth/update-password` — password recovery

## 4. Local development

```bash
npm install
npm run check:env
npm run check:supabase
npm run dev
```

Open `http://localhost:3000`.

## 5. Production verification

Before pushing/deploying:

```bash
npm run typecheck
npm run lint
npm run build
```

There is intentionally **no** `postcss.config.*` and **no** Tailwind dependency. This prevents the previous Vercel error:

```text
Cannot find module 'tailwindcss'
```

## 6. Vercel

Import the GitHub repository into Vercel and configure:

```env
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=...
NEXT_PUBLIC_SITE_URL=https://YOUR_PRODUCTION_DOMAIN
```

Then deploy. After deployment verify:

```text
https://YOUR_DOMAIN/api/health
```

Healthy response should contain:

```json
{
  "ok": true,
  "supabase": { "ok": true, "status": 200 }
}
```

## 7. Security model

### Day locking

The current available day is calculated from the server/database using the enrollment start date and the user's stored IANA timezone. Future content is not merely hidden in the UI: RLS on `lesson_words` and `words` prevents reading future vocabulary via direct Supabase Data API calls.

### Sensitive writes

Learners have SELECT-only table privileges through RLS. Mutations use narrowly scoped RPC functions:

- `complete_onboarding_and_start`
- `submit_daily_quiz`
- `submit_word_review`
- `admin_import_lesson`

`admin_import_lesson` checks `profiles.role = 'admin'` inside a `SECURITY DEFINER` transaction.

### Quiz integrity

The browser submits `wordId + selectedMeaning`. PostgreSQL resolves the expected answer from the learner's actual lesson and calculates the score itself.

## 8. Curriculum

`supabase/seed.sql` only adds Day 1 smoke-test content for all learner segments. Before public launch, load production content for all days/segments using `/admin`.

Each learner segment requires:

```text
100 days × 10 words = 1,000 lesson-word assignments
```

Words can be reused across segments, so the `words` table does not necessarily need 8,000 unique rows.

## 9. GitHub

```bash
git add -A
git commit -m "fix: production-ready Supabase and Vercel build"
git push origin main
```

The included GitHub Actions workflow verifies typecheck, lint and build on pushes/PRs.
