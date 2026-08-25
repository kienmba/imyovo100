# Production checklist

- [ ] Run `supabase/schema.sql`
- [ ] Run `supabase/seed.sql` for smoke test
- [ ] Create production admin user and set `profiles.role='admin'`
- [ ] Import and QA 8 × 100 × 10 curriculum
- [ ] Run `npm run validate:curriculum`
- [ ] Configure Supabase Site URL / Redirect URLs
- [ ] Configure production SMTP
- [ ] Configure Vercel environment variables
- [ ] Configure custom domain
- [ ] Enable Supabase backups/PITR appropriate to plan
- [ ] Add monitoring/error tracking DSN
- [ ] Add privacy/terms/children-data consent requirements as applicable
- [ ] Run GitHub CI green
- [ ] Smoke test signup → onboarding → Day 1 → quiz → review → history
- [ ] Verify future-day content is inaccessible via Supabase Data API
- [ ] Upgrade Next.js to the August 26, 2026 security patch (or later) before public traffic
