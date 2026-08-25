# ImYoVo100 — production-ready application baseline

Web app học 1.000 từ tiếng Anh trong 100 ngày, xây bằng Next.js + Supabase.

## Tính năng
- Supabase Auth email/password, SSR session bằng cookies.
- Onboarding và 8 nhóm: Tiền tiểu học, Tiểu học, THCS, THPT, Đại học, Sau đại học, Đi làm, Người lớn tuổi.
- Enrollment 100 ngày; Day tương lai khóa ở database.
- Curriculum tách theo `learner_type`: cùng Day có thể có 10 từ khác nhau cho từng nhóm.
- Flashcard + Quiz 10 câu/ngày.
- Database tự chấm Quiz; browser không được tự khai báo đáp án đúng.
- Progress, best score, attempts, streak, history.
- Spaced repetition theo từng từ và review queue.
- RLS cho toàn bộ bảng public.
- Không cho user tự sửa `role` hoặc `started_on`.
- Admin import curriculum theo Day + nhóm người học.
- Service role chỉ nằm server-side.
- Vercel-ready.

## 1. Supabase

Tạo project Supabase. Trong SQL Editor chạy:

```text
supabase/schema.sql
supabase/seed.sql
```

`schema.sql` tạo 100 Lesson. `seed.sql` chỉ có 10 từ Day 1 dùng để smoke test và copy cho 8 nhóm.

### Cấp quyền Admin

Sau khi user đã đăng ký:

```sql
update public.profiles
set role = 'admin'
where id = '<AUTH_USER_UUID>';
```

Không có API learner-facing nào cho phép tự nâng quyền Admin.

## 2. Environment variables

Copy `.env.example` thành `.env.local`:

```env
NEXT_PUBLIC_SITE_URL=http://localhost:3000
NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
```

`SUPABASE_SERVICE_ROLE_KEY` tuyệt đối không có prefix `NEXT_PUBLIC_`.

## 3. Supabase Auth URL Configuration

Development:

```text
Site URL: http://localhost:3000
Redirect URL: http://localhost:3000/auth/callback
```

Production thêm:

```text
https://<your-domain>/auth/callback
```

## 4. Chạy local

```bash
npm install
npm run typecheck
npm run build
npm run dev
```

## 5. Quy tắc khóa Day

`enrollments.started_on` chỉ được tạo bởi RPC `complete_onboarding_and_start()`, sử dụng `current_date` của database.

`get_course_access()` tính:

```text
available_day = current_date - started_on + 1
```

và giới hạn 1..100.

RLS của `words` và `lesson_words` chỉ cho đọc nội dung thuộc Day đã mở và đúng `learner_type`.

`submit_daily_quiz()` tiếp tục kiểm tra Day ở database trước khi ghi progress.

Do đó:
- sửa JavaScript frontend không mở được Day tương lai;
- gọi Data API trực tiếp cũng không đọc được word content tương lai;
- tự gửi `correct=true` không gian lận được Quiz.

## 6. Curriculum 100 ngày × 8 nhóm

Admin truy cập `/admin` để import một payload:

```json
{
  "dayNumber": 1,
  "learnerType": "working",
  "title": "Day 1 — Daily Routine",
  "theme": "Daily Routine",
  "words": [
    {
      "term": "commute",
      "ipa": "/kəˈmjuːt/",
      "meaning_vi": "đi lại giữa nhà và nơi làm việc",
      "part_of_speech": "verb",
      "example_en": "I commute by bus.",
      "example_vi": "Tôi đi làm bằng xe buýt."
    }
  ]
}
```

`words` bắt buộc đúng 10 item.

Production launch cần QA đủ:
- 100 Day
- × 8 learner segments
- × 10 từ/Day

Có thể tái sử dụng một word giữa nhiều nhóm/Day.

## 7. Spaced repetition

Sau Quiz, database cập nhật:
- `repetitions`
- `interval_days`
- `ease_factor`
- `correct_count`
- `wrong_count`
- `next_review_at`

Các từ đến hạn xuất hiện ở `/review`.

## 8. Deploy Vercel

1. Push repo lên GitHub.
2. Import repo trong Vercel.
3. Set 4 environment variables.
4. Deploy.
5. Cập nhật Supabase Site URL + Redirect URL sang domain Vercel/custom domain.

## 9. Git

```bash
git add .
git commit -m "feat: production-ready ImYoVo100 baseline"
git push origin main
```

## 10. Checklist trước public launch

Codebase đã có các guard chính cho production, nhưng các hạng mục phụ thuộc tài khoản/dữ liệu bên ngoài vẫn cần hoàn thiện:

- QA toàn bộ curriculum 100 × 8 × 10.
- Nguồn audio phát âm có bản quyền/quyền sử dụng.
- SMTP production cho email xác nhận/reset password.
- Custom domain.
- Monitoring/error tracking (Sentry hoặc dịch vụ tương đương).
- Privacy Policy / Terms / consent nếu thu thập dữ liệu trẻ em.
- Backup/restore policy cho Supabase.
- E2E test trên production-like environment.


## Dependency note — 25/08/2026

Project đang dùng dải Next.js `^16.3.2` và Supabase SSR `^0.12.5`. Next.js đã thông báo bản vá bảo mật theo lịch vào 26/08/2026; hãy chạy `npm update next` và deploy lại trước khi mở public traffic.
