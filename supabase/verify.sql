-- Run after schema.sql (and optionally seed.sql) to verify the deployment.
-- All rows should report PASS.

with checks as (
  select 'course_exists' name,
    exists(select 1 from public.courses where slug='english-1000-in-100-days' and active) ok,
    'Expected active course english-1000-in-100-days' detail
  union all
  select '100_lessons',
    (select count(*)=100 from public.lessons l join public.courses c on c.id=l.course_id where c.slug='english-1000-in-100-days'),
    'Expected exactly 100 lesson shells'
  union all
  select 'rls_profiles',
    (select relrowsecurity from pg_class where oid='public.profiles'::regclass),
    'RLS must be enabled on profiles'
  union all
  select 'rls_words',
    (select relrowsecurity from pg_class where oid='public.words'::regclass),
    'RLS must be enabled on words'
  union all
  select 'rpc_onboarding',
    to_regprocedure('public.complete_onboarding_and_start(text,text,public.learner_type,text)') is not null,
    'Onboarding RPC must exist'
  union all
  select 'rpc_access',
    to_regprocedure('public.get_course_access(uuid)') is not null,
    'Course access RPC must exist'
  union all
  select 'rpc_quiz',
    to_regprocedure('public.submit_daily_quiz(uuid,integer,jsonb)') is not null,
    'Quiz RPC must exist'
  union all
  select 'rpc_review',
    to_regprocedure('public.submit_word_review(uuid,integer)') is not null,
    'Review RPC must exist'
  union all
  select 'rpc_admin_import',
    to_regprocedure('public.admin_import_lesson(text,integer,text,text,public.learner_type,jsonb)') is not null,
    'Atomic admin import RPC must exist'
)
select case when ok then 'PASS' else 'FAIL' end status,name,detail from checks order by name;
