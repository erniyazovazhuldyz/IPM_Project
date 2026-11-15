-- QazRoute · Sprint 3 · Пара 1 «Аккаунт и профиль»
-- Запустить ОДИН раз: Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Можно запускать повторно — ничего не сломается (if not exists / on conflict / drop ... if exists).
--
-- Что создаётся:
--   1. Таблица public.profiles — данные пользователя (имя, город, аватар).
--   2. Триггер: профиль создаётся САМ, когда человек регистрируется.
--   3. RLS: каждый видит и меняет ТОЛЬКО свой профиль.
--   4. Storage bucket "avatars" для фото профиля + правила доступа к нему.

-- ---------------------------------------------------------------------------
-- 1. Таблица профилей
-- ---------------------------------------------------------------------------
-- id совпадает с id пользователя в auth.users (там Supabase хранит email и пароль).
-- on delete cascade: если удалить пользователя, его профиль удалится тоже.
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text,
  full_name   text,
  city        text,
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- updated_at обновляется автоматически при каждом изменении строки
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 2. Профиль создаётся при регистрации
-- ---------------------------------------------------------------------------
-- Приложение при регистрации передаёт имя в metadata: data: {'full_name': ...}
-- security definer — функция работает с правами владельца, иначе ей не дадут
-- писать в profiles от имени ещё не вошедшего пользователя.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    nullif(trim(new.raw_user_meta_data ->> 'full_name'), '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Пользователи, которые зарегистрировались ДО этой миграции, тоже получают профиль
insert into public.profiles (id, email)
select id, email from auth.users
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- 3. RLS (Row Level Security) — кто что может делать с profiles
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles: insert own" on public.profiles;
create policy "profiles: insert own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: update own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Удалять профиль из приложения нельзя (он удаляется вместе с аккаунтом).

-- ---------------------------------------------------------------------------
-- 4. Аватары: Storage bucket "avatars"
-- ---------------------------------------------------------------------------
-- public = true: картинку можно открыть по ссылке (нужно, чтобы показать её в приложении).
-- Файл каждого пользователя лежит в папке с его id: avatars/<user-id>/avatar.jpg
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880,               -- максимум 5 МБ
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars: public read" on storage.objects;
create policy "avatars: public read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'avatars');

drop policy if exists "avatars: upload own" on storage.objects;
create policy "avatars: upload own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars: update own" on storage.objects;
create policy "avatars: update own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars: delete own" on storage.objects;
create policy "avatars: delete own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- Проверка: должны увидеть по строке на каждого зарегистрированного пользователя
-- ---------------------------------------------------------------------------
select id, email, full_name, city, avatar_url, created_at
  from public.profiles
 order by created_at;
