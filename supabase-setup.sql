-- WealthOS: schema và Row Level Security cho Supabase
-- Chạy toàn bộ file này trong Supabase SQL Editor.

create table if not exists public.wealth_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default timezone('utc', now()),
  constraint wealth_data_user_id_unique unique (user_id)
);

create index if not exists wealth_data_user_id_idx on public.wealth_data(user_id);

alter table public.wealth_data enable row level security;

-- Mỗi user chỉ được đọc bản ghi của chính mình.
drop policy if exists "Users can read their own wealth data" on public.wealth_data;
create policy "Users can read their own wealth data"
on public.wealth_data
for select
to authenticated
using (auth.uid() = user_id);

-- Mỗi user chỉ được tạo bản ghi có user_id trùng với tài khoản đang đăng nhập.
drop policy if exists "Users can insert their own wealth data" on public.wealth_data;
create policy "Users can insert their own wealth data"
on public.wealth_data
for insert
to authenticated
with check (auth.uid() = user_id);

-- Mỗi user chỉ được cập nhật bản ghi của chính mình và không được đổi chủ sở hữu.
drop policy if exists "Users can update their own wealth data" on public.wealth_data;
create policy "Users can update their own wealth data"
on public.wealth_data
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Cho phép xóa dữ liệu của chính mình nếu chức năng này được dùng sau này.
drop policy if exists "Users can delete their own wealth data" on public.wealth_data;
create policy "Users can delete their own wealth data"
on public.wealth_data
for delete
to authenticated
using (auth.uid() = user_id);

-- Ghi chú mở rộng admin (chưa bật):
-- Admin hiện được xác định ở phía giao diện bằng email tung.edtech@gmail.com.
-- Khi triển khai danh sách users, không nên dùng anon key để đọc auth.users.
-- Hãy tạo Edge Function hoặc bảng public user_profiles với policy/role riêng cho admin.

comment on table public.wealth_data is 'One private WealthOS JSON document per authenticated user';
comment on column public.wealth_data.data is 'Serialized WealthOS application state';
