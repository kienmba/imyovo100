
-- Day 1 smoke-test content.
-- It is copied to all 8 learner segments so every account can test the flow.
-- Replace each segment/day using /admin before public launch.
with c as (
  select id from public.courses where slug='english-1000-in-100-days'
), l as (
  select id from public.lessons where course_id=(select id from c) and day_number=1
), source(term,ipa,meaning_vi,part_of_speech,example_en,example_vi) as (
values
('wake up','/weɪk ʌp/','thức dậy','phrasal verb','I wake up at six.','Tôi thức dậy lúc sáu giờ.'),
('brush','/brʌʃ/','đánh / chải','verb','I brush my teeth.','Tôi đánh răng.'),
('breakfast','/ˈbrekfəst/','bữa sáng','noun','Breakfast is ready.','Bữa sáng đã sẵn sàng.'),
('commute','/kəˈmjuːt/','đi lại giữa nhà và nơi làm việc','verb','I commute by bus.','Tôi đi làm bằng xe buýt.'),
('work','/wɜːrk/','làm việc','verb','I work in an office.','Tôi làm việc trong văn phòng.'),
('study','/ˈstʌdi/','học','verb','I study English daily.','Tôi học tiếng Anh hằng ngày.'),
('read','/riːd/','đọc','verb','I read every evening.','Tôi đọc sách mỗi tối.'),
('write','/raɪt/','viết','verb','I write a short note.','Tôi viết một ghi chú ngắn.'),
('listen','/ˈlɪsən/','nghe','verb','Listen carefully.','Hãy nghe cẩn thận.'),
('speak','/spiːk/','nói','verb','I speak English at work.','Tôi nói tiếng Anh ở nơi làm việc.')
), upserted as (
  insert into public.words(term,ipa,meaning_vi,part_of_speech,example_en,example_vi)
  select * from source
  on conflict(term,meaning_vi) do update set
    ipa=excluded.ipa,part_of_speech=excluded.part_of_speech,
    example_en=excluded.example_en,example_vi=excluded.example_vi
  returning id,term
), segments as (
  select unnest(enum_range(null::public.learner_type)) learner_type
)
insert into public.lesson_words(lesson_id,learner_type,word_id,position)
select
  (select id from l),
  s.learner_type,
  w.id,
  row_number() over(
    partition by s.learner_type
    order by array_position(
      array['wake up','brush','breakfast','commute','work','study','read','write','listen','speak'],
      w.term
    )
  )
from upserted w cross join segments s
on conflict(lesson_id,learner_type,position) do update set word_id=excluded.word_id;
