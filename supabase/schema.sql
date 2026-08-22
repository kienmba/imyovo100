create extension if not exists pgcrypto;

create type learner_type as enum ('preschool','primary','middle_school','high_school','university','postgraduate','working','senior');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  learner_type learner_type not null default 'working',
  learning_start_date date,
  timezone text not null default 'Asia/Ho_Chi_Minh',
  created_at timestamptz not null default now()
);

create table public.words (
  id uuid primary key default gen_random_uuid(),
  word text not null,
  ipa text,
  meaning_vi text not null,
  example_en text,
  example_vi text,
  audio_url text,
  created_at timestamptz not null default now()
);

create table public.day_words (
  day_number int not null check(day_number between 1 and 100),
  word_id uuid not null references public.words(id) on delete cascade,
  position int not null check(position between 1 and 10),
  primary key(day_number,position),
  unique(day_number,word_id)
);

create table public.user_day_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  day_number int not null check(day_number between 1 and 100),
  status text not null default 'started' check(status in ('started','completed')),
  started_at timestamptz,
  completed_at timestamptz,
  primary key(user_id,day_number)
);

create table public.user_word_progress (
  user_id uuid not null references public.profiles(id) on delete cascade,
  word_id uuid not null references public.words(id) on delete cascade,
  correct_count int not null default 0,
  wrong_count int not null default 0,
  last_seen_at timestamptz,
  primary key(user_id,word_id)
);

alter table public.profiles enable row level security;
alter table public.words enable row level security;
alter table public.day_words enable row level security;
alter table public.user_day_progress enable row level security;
alter table public.user_word_progress enable row level security;

create policy "profiles own" on public.profiles for all using(auth.uid()=id) with check(auth.uid()=id);
create policy "words readable" on public.words for select to authenticated using(true);
create policy "day words readable" on public.day_words for select to authenticated using(true);
create policy "progress own" on public.user_day_progress for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "word progress own" on public.user_word_progress for all using(auth.uid()=user_id) with check(auth.uid()=user_id);

create or replace function public.enforce_day_access()
returns trigger language plpgsql security definer as $$
declare start_date date; allowed_day int;
begin
  select learning_start_date into start_date from public.profiles where id=auth.uid();
  allowed_day := greatest(0, current_date - start_date + 1);
  if NEW.day_number > allowed_day then
    raise exception 'DAY_LOCKED: day % is not available yet', NEW.day_number;
  end if;
  return NEW;
end; $$;

create trigger trg_enforce_day_access before insert or update on public.user_day_progress
for each row execute function public.enforce_day_access();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
 insert into public.profiles(id,display_name,learning_start_date)
 values(new.id,coalesce(new.raw_user_meta_data->>'display_name',''),current_date)
 on conflict(id) do nothing;
 return new;
end; $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- Seed example. Replace/import with your real 1,000-word curriculum.
insert into public.words(word,ipa,meaning_vi,example_en,example_vi) values
('wake up','/weɪk ʌp/','thức dậy','I wake up at seven.','Tôi thức dậy lúc bảy giờ.'),
('brush','/brʌʃ/','đánh răng','I brush my teeth every morning.','Tôi đánh răng mỗi sáng.'),
('breakfast','/ˈbrekfəst/','bữa sáng','Breakfast is ready.','Bữa sáng đã sẵn sàng.'),
('commute','/kəˈmjuːt/','đi lại','I commute by bus.','Tôi đi làm bằng xe buýt.'),
('work','/wɜːrk/','làm việc','I work from Monday to Friday.','Tôi làm việc từ thứ Hai đến thứ Sáu.'),
('study','/ˈstʌdi/','học','I study English every day.','Tôi học tiếng Anh mỗi ngày.'),
('read','/riːd/','đọc','I read a book.','Tôi đọc một cuốn sách.'),
('write','/raɪt/','viết','I write in my notebook.','Tôi viết vào vở.'),
('listen','/ˈlɪsən/','nghe','Listen carefully.','Hãy nghe cẩn thận.'),
('speak','/spiːk/','nói','I speak English at work.','Tôi nói tiếng Anh ở nơi làm việc.');

insert into public.day_words(day_number,word_id,position)
select 1,id,row_number() over(order by created_at) from public.words limit 10;
