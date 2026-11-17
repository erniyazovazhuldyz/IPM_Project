-- QazRoute · US-10 «Сохранение маршрутов» (Saved routes)
-- Запустить ОДИН раз: Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Нужны уже запущенные schema.sql (таблица routes) и вход по email (Sprint 3, Пара 1).
-- Можно запускать повторно — ничего не сломается.
--
-- Что создаётся:
--   1. Таблица public.saved_routes — какие маршруты сохранил пользователь.
--   2. RLS: каждый видит, добавляет и удаляет ТОЛЬКО свои сохранённые маршруты.

-- ---------------------------------------------------------------------------
-- 1. Таблица
-- ---------------------------------------------------------------------------
-- Одна строка = «пользователь user_id сохранил маршрут route_id».
-- primary key (user_id, route_id): один и тот же маршрут нельзя сохранить дважды.
-- on delete cascade: удалили пользователя или маршрут — строка удаляется сама.
create table if not exists public.saved_routes (
  user_id     uuid        not null references auth.users (id) on delete cascade,
  route_id    bigint      not null references public.routes (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, route_id)
);

-- Быстро получить «мои сохранённые, сначала новые».
create index if not exists saved_routes_user_created_idx
  on public.saved_routes (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 2. RLS — кто что может делать
-- ---------------------------------------------------------------------------
alter table public.saved_routes enable row level security;

drop policy if exists "saved_routes: read own" on public.saved_routes;
create policy "saved_routes: read own"
  on public.saved_routes for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "saved_routes: insert own" on public.saved_routes;
create policy "saved_routes: insert own"
  on public.saved_routes for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "saved_routes: delete own" on public.saved_routes;
create policy "saved_routes: delete own"
  on public.saved_routes for delete
  to authenticated
  using (auth.uid() = user_id);

-- Изменять строку не нужно (только сохранить / убрать), поэтому update-правила нет.

-- ---------------------------------------------------------------------------
-- Проверка: таблица есть, пока пустая (или ваши тестовые строки)
-- ---------------------------------------------------------------------------
select s.user_id, s.route_id, r.title, s.created_at
  from public.saved_routes s
  join public.routes r on r.id = s.route_id
 order by s.created_at desc;
