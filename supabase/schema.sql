begin;

create extension if not exists pgcrypto;

do $$ begin create type public.learner_type as enum
('preschool','primary','middle_school','high_school','university','postgraduate','working','senior');
exception when duplicate_object then null; end $$;

do $$ begin create type public.app_role as enum ('learner','admin');
exception when duplicate_object then null; end $$;

create table if not exists public.profiles(
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  learner_type public.learner_type not null default 'working',
  role public.app_role not null default 'learner',
  timezone text not null default 'Asia/Ho_Chi_Minh',
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.courses(
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title text not null,
  description text,
  total_days int not null default 100 check(total_days=100),
  words_per_day int not null default 10 check(words_per_day=10),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.enrollments(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  started_on date not null default current_date,
  status text not null default 'active' check(status in ('active','paused','completed')),
  created_at timestamptz not null default now(),
  unique(user_id,course_id)
);

create table if not exists public.lessons(
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  day_number int not null check(day_number between 1 and 100),
  title text not null,
  theme text not null,
  created_at timestamptz not null default now(),
  unique(course_id,day_number)
);

create table if not exists public.words(
  id uuid primary key default gen_random_uuid(),
  term text not null,
  ipa text,
  meaning_vi text not null,
  part_of_speech text,
  example_en text,
  example_vi text,
  audio_url text,
  created_at timestamptz not null default now(),
  unique(term,meaning_vi)
);

create table if not exists public.lesson_words(
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  learner_type public.learner_type not null,
  word_id uuid not null references public.words(id) on delete cascade,
  position int not null check(position between 1 and 10),
  primary key(lesson_id,learner_type,position),
  unique(lesson_id,learner_type,word_id)
);

create table if not exists public.lesson_progress(
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  day_number int not null check(day_number between 1 and 100),
  status text not null default 'started' check(status in ('started','completed')),
  best_score int check(best_score between 0 and 10),
  attempts int not null default 0,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key(user_id,course_id,day_number)
);

create table if not exists public.quiz_attempts(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  day_number int not null check(day_number between 1 and 100),
  score int not null check(score between 0 and 10),
  total int not null check(total=10),
  answers jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists public.user_word_progress(
  user_id uuid not null references public.profiles(id) on delete cascade,
  word_id uuid not null references public.words(id) on delete cascade,
  repetitions int not null default 0,
  interval_days int not null default 0,
  ease_factor numeric(4,2) not null default 2.50,
  correct_count int not null default 0,
  wrong_count int not null default 0,
  last_seen_at timestamptz,
  next_review_at timestamptz not null default now(),
  primary key(user_id,word_id)
);

create index if not exists idx_lessons_course_day on public.lessons(course_id,day_number);
create index if not exists idx_lw_lesson_segment on public.lesson_words(lesson_id,learner_type,position);
create index if not exists idx_progress_user_course on public.lesson_progress(user_id,course_id,day_number);
create index if not exists idx_review_due on public.user_word_progress(user_id,next_review_at);
create index if not exists idx_quiz_user_created on public.quiz_attempts(user_id,created_at desc);

alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.enrollments enable row level security;
alter table public.lessons enable row level security;
alter table public.words enable row level security;
alter table public.lesson_words enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.user_word_progress enable row level security;

-- Read-only policies for learner-facing tables.
drop policy if exists "profiles own read" on public.profiles;
create policy "profiles own read" on public.profiles for select using(auth.uid()=id);

drop policy if exists "course authenticated read" on public.courses;
create policy "course authenticated read" on public.courses for select to authenticated using(active=true);

drop policy if exists "enrollments own read" on public.enrollments;
create policy "enrollments own read" on public.enrollments for select using(auth.uid()=user_id);

drop policy if exists "lessons authenticated read" on public.lessons;
create policy "lessons authenticated read" on public.lessons for select to authenticated using(true);

drop policy if exists "progress own read" on public.lesson_progress;
create policy "progress own read" on public.lesson_progress for select using(auth.uid()=user_id);

drop policy if exists "quiz own read" on public.quiz_attempts;
create policy "quiz own read" on public.quiz_attempts for select using(auth.uid()=user_id);

drop policy if exists "word progress own read" on public.user_word_progress;
create policy "word progress own read" on public.user_word_progress for select using(auth.uid()=user_id);

-- Explicit API privileges: learners read through RLS and write only through RPCs.
revoke insert,update,delete on public.profiles,public.courses,public.enrollments,public.lessons,public.words,public.lesson_words,public.lesson_progress,public.quiz_attempts,public.user_word_progress from anon,authenticated;
grant select on public.profiles,public.courses,public.enrollments,public.lessons,public.words,public.lesson_words,public.lesson_progress,public.quiz_attempts,public.user_word_progress to authenticated;

-- Word content is visible only when it is part of an unlocked lesson for the
-- user's learner segment, or the word is already in that user's review queue.
drop policy if exists "unlocked words read" on public.words;
create policy "unlocked words read" on public.words for select to authenticated using(
  exists(
    select 1
    from public.lesson_words lw
    join public.lessons l on l.id=lw.lesson_id
    join public.enrollments e on e.course_id=l.course_id and e.user_id=auth.uid() and e.status='active'
    join public.profiles p on p.id=auth.uid()
    where lw.word_id=words.id
      and lw.learner_type=p.learner_type
      and l.day_number <= least(100,greatest(1,(now() at time zone p.timezone)::date-e.started_on+1))
  )
  or exists(select 1 from public.user_word_progress uw where uw.user_id=auth.uid() and uw.word_id=words.id)
);

drop policy if exists "unlocked lesson words read" on public.lesson_words;
create policy "unlocked lesson words read" on public.lesson_words for select to authenticated using(
  exists(
    select 1
    from public.lessons l
    join public.enrollments e on e.course_id=l.course_id and e.user_id=auth.uid() and e.status='active'
    join public.profiles p on p.id=auth.uid()
    where l.id=lesson_words.lesson_id
      and lesson_words.learner_type=p.learner_type
      and l.day_number <= least(100,greatest(1,(now() at time zone p.timezone)::date-e.started_on+1))
  )
);

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public,pg_temp as $$
begin
  insert into public.profiles(id,display_name)
  values(new.id,coalesce(new.raw_user_meta_data->>'display_name',''))
  on conflict(id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.complete_onboarding_and_start(
  p_course_slug text,
  p_display_name text,
  p_learner_type public.learner_type,
  p_timezone text
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare v_course uuid;
begin
  if auth.uid() is null then raise exception 'UNAUTHORIZED'; end if;
  select id into v_course from public.courses where slug=p_course_slug and active=true;
  if v_course is null then raise exception 'COURSE_NOT_FOUND'; end if;
  if not exists(select 1 from pg_timezone_names where name=p_timezone) then raise exception 'INVALID_TIMEZONE'; end if;
  if length(trim(p_display_name))<2 then raise exception 'INVALID_DISPLAY_NAME'; end if;

  update public.profiles
  set display_name=left(trim(p_display_name),80),
      learner_type=p_learner_type,
      timezone=left(p_timezone,64),
      onboarding_completed=true,
      updated_at=now()
  where id=auth.uid();

  insert into public.enrollments(user_id,course_id,started_on,status)
  values(auth.uid(),v_course,(now() at time zone p_timezone)::date,'active')
  on conflict(user_id,course_id) do nothing;

  return jsonb_build_object('ok',true);
end $$;

create or replace function public.get_course_access(p_course_id uuid)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare e public.enrollments%rowtype; v_available int; v_completed int; v_streak int:=0; v_day int;
begin
  if auth.uid() is null then raise exception 'UNAUTHORIZED'; end if;
  select * into e from public.enrollments
  where user_id=auth.uid() and course_id=p_course_id and status='active';
  if e.id is null then raise exception 'NOT_ENROLLED'; end if;

  v_available:=least(100,greatest(1,
    (now() at time zone (select timezone from public.profiles where id=auth.uid()))::date
    - e.started_on + 1));
  select count(*) into v_completed from public.lesson_progress
  where user_id=auth.uid() and course_id=p_course_id and status='completed';

  v_day:=least(v_available,(select coalesce(max(day_number),0) from public.lesson_progress
    where user_id=auth.uid() and course_id=p_course_id and status='completed'));
  while v_day>0 and exists(select 1 from public.lesson_progress
    where user_id=auth.uid() and course_id=p_course_id and day_number=v_day and status='completed')
  loop
    v_streak:=v_streak+1; v_day:=v_day-1;
  end loop;

  return jsonb_build_object(
    'available_day',v_available,
    'completed_days',v_completed,
    'current_streak',v_streak
  );
end $$;

create or replace function public.submit_daily_quiz(
  p_course_id uuid,
  p_day_number int,
  p_answers jsonb
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare
  e public.enrollments%rowtype;
  p public.profiles%rowtype;
  v_available int;
  v_total int;
  v_score int:=0;
  a jsonb;
  v_word uuid;
  v_selected text;
  v_correct boolean;
  v_expected text;
  uw public.user_word_progress%rowtype;
  v_interval int;
  v_ease numeric;
begin
  if auth.uid() is null then raise exception 'UNAUTHORIZED'; end if;
  if p_day_number<1 or p_day_number>100 then raise exception 'INVALID_DAY'; end if;

  select * into e from public.enrollments
  where user_id=auth.uid() and course_id=p_course_id and status='active';
  if e.id is null then raise exception 'NOT_ENROLLED'; end if;
  select * into p from public.profiles where id=auth.uid();

  v_available:=least(100,greatest(1,
    (now() at time zone (select timezone from public.profiles where id=auth.uid()))::date
    - e.started_on + 1));
  if p_day_number>v_available then raise exception 'DAY_LOCKED'; end if;

  select count(*) into v_total from jsonb_array_elements(p_answers);
  if v_total<>10 then raise exception 'QUIZ_MUST_HAVE_10_ANSWERS'; end if;
  if (select count(distinct (j->>'wordId')) from jsonb_array_elements(p_answers) j)<>10 then
    raise exception 'QUIZ_REQUIRES_10_UNIQUE_WORDS';
  end if;

  for a in select * from jsonb_array_elements(p_answers)
  loop
    v_word:=(a->>'wordId')::uuid;
    v_selected:=a->>'selectedMeaning';

    select w.meaning_vi into v_expected
    from public.words w
    join public.lesson_words lw on lw.word_id=w.id
    join public.lessons l on l.id=lw.lesson_id
    where w.id=v_word
      and l.course_id=p_course_id
      and l.day_number=p_day_number
      and lw.learner_type=p.learner_type;

    if v_expected is null then raise exception 'WORD_NOT_IN_LESSON'; end if;
    v_correct:=v_selected=v_expected;
    if v_correct then v_score:=v_score+1; end if;

    select * into uw from public.user_word_progress
    where user_id=auth.uid() and word_id=v_word;
    if not found then
      uw.repetitions:=0; uw.interval_days:=0; uw.ease_factor:=2.50;
      uw.correct_count:=0; uw.wrong_count:=0;
    end if;

    if v_correct then
      uw.repetitions:=uw.repetitions+1;
      v_interval:=case when uw.repetitions=1 then 1
        when uw.repetitions=2 then 3
        else greatest(1,round(uw.interval_days*uw.ease_factor)::int) end;
      v_ease:=least(3.00,uw.ease_factor+0.05);
    else
      uw.repetitions:=0; v_interval:=1; v_ease:=greatest(1.30,uw.ease_factor-0.20);
    end if;

    insert into public.user_word_progress(
      user_id,word_id,repetitions,interval_days,ease_factor,
      correct_count,wrong_count,last_seen_at,next_review_at
    ) values(
      auth.uid(),v_word,uw.repetitions,v_interval,v_ease,
      uw.correct_count+(case when v_correct then 1 else 0 end),
      uw.wrong_count+(case when v_correct then 0 else 1 end),
      now(),now()+(v_interval||' days')::interval
    )
    on conflict(user_id,word_id) do update set
      repetitions=excluded.repetitions,interval_days=excluded.interval_days,
      ease_factor=excluded.ease_factor,correct_count=excluded.correct_count,
      wrong_count=excluded.wrong_count,last_seen_at=excluded.last_seen_at,
      next_review_at=excluded.next_review_at;
  end loop;

  insert into public.quiz_attempts(user_id,course_id,day_number,score,total,answers)
  values(auth.uid(),p_course_id,p_day_number,v_score,v_total,p_answers);

  insert into public.lesson_progress(
    user_id,course_id,day_number,status,best_score,attempts,completed_at,updated_at
  ) values(auth.uid(),p_course_id,p_day_number,'completed',v_score,1,now(),now())
  on conflict(user_id,course_id,day_number) do update set
    status='completed',
    best_score=greatest(coalesce(public.lesson_progress.best_score,0),excluded.best_score),
    attempts=public.lesson_progress.attempts+1,
    completed_at=coalesce(public.lesson_progress.completed_at,now()),
    updated_at=now();

  return jsonb_build_object('score',v_score,'total',v_total,'completed',true);
end $$;

revoke all on function public.complete_onboarding_and_start(text,text,public.learner_type,text) from public;
grant execute on function public.complete_onboarding_and_start(text,text,public.learner_type,text) to authenticated;
revoke all on function public.get_course_access(uuid) from public;
grant execute on function public.get_course_access(uuid) to authenticated;
revoke all on function public.submit_daily_quiz(uuid,int,jsonb) from public;
grant execute on function public.submit_daily_quiz(uuid,int,jsonb) to authenticated;


create or replace function public.submit_word_review(p_word_id uuid,p_quality int)
returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare uw public.user_word_progress%rowtype; v_interval int; v_ease numeric; v_rep int;
begin
  if auth.uid() is null then raise exception 'UNAUTHORIZED'; end if;
  if p_quality<0 or p_quality>5 then raise exception 'INVALID_QUALITY'; end if;
  select * into uw from public.user_word_progress where user_id=auth.uid() and word_id=p_word_id;
  if not found then raise exception 'WORD_NOT_IN_REVIEW_QUEUE'; end if;
  if uw.next_review_at>now() then raise exception 'WORD_NOT_DUE_YET'; end if;

  if p_quality<3 then
    v_rep:=0; v_interval:=1; v_ease:=greatest(1.30,uw.ease_factor-0.20);
  else
    v_rep:=uw.repetitions+1;
    v_interval:=case when v_rep=1 then 1 when v_rep=2 then 3 else greatest(1,round(uw.interval_days*uw.ease_factor)::int) end;
    v_ease:=least(3.00,greatest(1.30,uw.ease_factor+(0.10-(5-p_quality)*0.08)));
  end if;

  update public.user_word_progress set
    repetitions=v_rep,interval_days=v_interval,ease_factor=v_ease,
    correct_count=correct_count+(case when p_quality>=3 then 1 else 0 end),
    wrong_count=wrong_count+(case when p_quality<3 then 1 else 0 end),
    last_seen_at=now(),next_review_at=now()+(v_interval||' days')::interval
  where user_id=auth.uid() and word_id=p_word_id;

  return jsonb_build_object('ok',true,'next_review_days',v_interval);
end $$;

revoke all on function public.submit_word_review(uuid,int) from public;
grant execute on function public.submit_word_review(uuid,int) to authenticated;



create or replace function public.admin_import_lesson(
  p_course_slug text,
  p_day_number int,
  p_title text,
  p_theme text,
  p_learner_type public.learner_type,
  p_words jsonb
) returns jsonb language plpgsql security definer set search_path=public,pg_temp as $$
declare
  v_course uuid;
  v_lesson uuid;
  v_role public.app_role;
  v_count int;
  v_item jsonb;
  v_word uuid;
  v_position int:=0;
begin
  if auth.uid() is null then raise exception 'UNAUTHORIZED'; end if;
  select role into v_role from public.profiles where id=auth.uid();
  if v_role is distinct from 'admin'::public.app_role then raise exception 'FORBIDDEN'; end if;
  if p_day_number<1 or p_day_number>100 then raise exception 'INVALID_DAY'; end if;
  if nullif(trim(p_title),'') is null or nullif(trim(p_theme),'') is null then raise exception 'INVALID_LESSON'; end if;

  select count(*) into v_count from jsonb_array_elements(p_words);
  if v_count<>10 then raise exception 'LESSON_MUST_HAVE_10_WORDS'; end if;

  select id into v_course from public.courses where slug=p_course_slug and active=true;
  if v_course is null then raise exception 'COURSE_NOT_FOUND'; end if;

  insert into public.lessons(course_id,day_number,title,theme)
  values(v_course,p_day_number,left(trim(p_title),120),left(trim(p_theme),120))
  on conflict(course_id,day_number) do update set title=excluded.title,theme=excluded.theme
  returning id into v_lesson;

  delete from public.lesson_words where lesson_id=v_lesson and learner_type=p_learner_type;

  for v_item in select * from jsonb_array_elements(p_words)
  loop
    v_position:=v_position+1;
    if nullif(trim(v_item->>'term'),'') is null or nullif(trim(v_item->>'meaning_vi'),'') is null then
      raise exception 'INVALID_WORD_AT_POSITION_%',v_position;
    end if;

    insert into public.words(term,ipa,meaning_vi,part_of_speech,example_en,example_vi,audio_url)
    values(
      left(trim(v_item->>'term'),80),
      nullif(left(coalesce(v_item->>'ipa',''),120),''),
      left(trim(v_item->>'meaning_vi'),240),
      nullif(left(coalesce(v_item->>'part_of_speech',''),40),''),
      nullif(left(coalesce(v_item->>'example_en',''),500),''),
      nullif(left(coalesce(v_item->>'example_vi',''),500),''),
      nullif(left(coalesce(v_item->>'audio_url',''),1000),'')
    )
    on conflict(term,meaning_vi) do update set
      ipa=excluded.ipa,
      part_of_speech=excluded.part_of_speech,
      example_en=excluded.example_en,
      example_vi=excluded.example_vi,
      audio_url=excluded.audio_url
    returning id into v_word;

    insert into public.lesson_words(lesson_id,learner_type,word_id,position)
    values(v_lesson,p_learner_type,v_word,v_position);
  end loop;

  return jsonb_build_object('ok',true,'lesson_id',v_lesson,'day_number',p_day_number,'learner_type',p_learner_type);
end $$;

revoke all on function public.admin_import_lesson(text,int,text,text,public.learner_type,jsonb) from public;
grant execute on function public.admin_import_lesson(text,int,text,text,public.learner_type,jsonb) to authenticated;

insert into public.courses(slug,title,description,total_days,words_per_day)
values('english-1000-in-100-days','1.000 từ tiếng Anh trong 100 ngày','10 từ mỗi ngày, mở khóa theo ngày.',100,10)
on conflict(slug) do update set title=excluded.title,description=excluded.description,active=true;

insert into public.lessons(course_id,day_number,title,theme)
select c.id,d,'Day '||d,case
  when d<=10 then 'Daily Life'
  when d<=20 then 'School & Learning'
  when d<=30 then 'People & Relationships'
  when d<=40 then 'Food & Health'
  when d<=50 then 'Travel & Places'
  when d<=60 then 'Work & Business'
  when d<=70 then 'Technology & Media'
  when d<=80 then 'Nature & Society'
  when d<=90 then 'Academic English'
  else 'Advanced Daily English' end
from public.courses c cross join generate_series(1,100) d
where c.slug='english-1000-in-100-days'
on conflict(course_id,day_number) do nothing;

commit;
