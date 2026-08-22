# 100 Days Vocabulary

Web app học 1.000 từ tiếng Anh trong 100 ngày.

## Stack
- Next.js + TypeScript
- Supabase Auth + PostgreSQL + RLS
- Vercel
- GitHub

## Chạy local
1. `npm install`
2. Tạo project Supabase.
3. Chạy `supabase/schema.sql` trong SQL Editor.
4. Copy `.env.example` thành `.env.local` và điền:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
5. `npm run dev`

## Quy tắc khóa ngày
Ngày khả dụng được tính từ `learning_start_date`. Frontend chỉ hiển thị ngày hợp lệ; database còn có trigger `enforce_day_access` để ngăn ghi progress cho ngày tương lai.

## Curriculum
Schema hỗ trợ 100 ngày x 10 từ. Bản mẫu có 10 từ Day 1 để kiểm thử. Cần import 990 từ còn lại vào `words` và `day_words`.

## Deploy Vercel
Import GitHub repository vào Vercel và khai báo hai biến môi trường Supabase. Sau đó Deploy.

## Git
```bash
git init
git add .
git commit -m "feat: initial 100 days vocabulary MVP"
git branch -M main
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
git push -u origin main
```
