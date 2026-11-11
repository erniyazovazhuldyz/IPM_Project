-- QazRoute · Sprint 2 · migration + verified trail data
-- Run ONCE in Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Safe to run again (uses "if not exists" / upsert).

-- 1. New columns (from BA trail card: Karakungei)
alter table public.routes
  add column if not exists slug             text unique,      -- human id, also usable in QR codes
  add column if not exists city             text,
  add column if not exists difficulty       text,             -- easy | moderate | hard
  add column if not exists elevation_gain_m integer,
  add column if not exists max_elevation_m  integer,
  add column if not exists is_verified      boolean not null default false,
  add column if not exists verified_at      date,
  add column if not exists verified_by      text;

-- distance in km, now with decimals (1.5 km)
alter table public.routes alter column distance type numeric(6,1);

-- 2. The old test row stays UNVERIFIED -> hidden in the app (TC-02)
update public.routes
   set city = 'Almaty', is_verified = false
 where title like 'TEST%';

-- 3. Karakungei (verified by BA, 2026-10-20)
--    Photos are bundled with the app: assets/trails/...
insert into public.routes
  (slug, title, city, location, description,
   preview_image_url, route_images_urls,
   completion_time, distance, elevation_gain_m, max_elevation_m, difficulty,
   is_verified, verified_at, verified_by, path)
values
  ('karakungei', 'Karakungei', 'Almaty',
   'Medeu area, Kim-Asar gorge road',
   'Shortest trail to the Karakungei summit viewpoint above Medeu. '
   'Start: turn-off from the Kim-Asar gorge road (Medeu lower parking), 1569 m. '
   '1.5 km one way (~3 km round trip), +216 m. 40-60 min to the summit, 1-1.5 h in total. '
   'Easy. Open all year; microspikes advised on shaded sections in winter.',
   'assets/trails/karakungei_1.jpg',
   array['assets/trails/karakungei_1.jpg', 'assets/trails/karakungei_2.jpg'],
   60, 1.5, 216, 1821, 'easy',
   true, '2026-10-20', 'Raimbek Ayaulym (BA)',
   array['43.163297,77.050543', '43.163607,77.050732', '43.163837,77.050615', '43.163988,77.05033',
         '43.164038,77.04987', '43.164168,77.049507', '43.16436,77.049583', '43.164578,77.049962',
         '43.164607,77.048462', '43.164873,77.048318', '43.165105,77.048397', '43.165128,77.048308',
         '43.166067,77.048318', '43.166635,77.048497', '43.167212,77.048497', '43.167388,77.048432',
         '43.16814,77.048637', '43.169048,77.048548', '43.169602,77.04867', '43.1699,77.048623',
         '43.170035,77.048527', '43.170115,77.04857', '43.170253,77.048472', '43.170743,77.048368',
         '43.170978,77.048195', '43.17152,77.048065', '43.17206,77.048073', '43.172348,77.047917',
         '43.172695,77.048105', '43.172775,77.04791', '43.172723,77.047722', '43.172335,77.04729',
         '43.171988,77.046608', '43.1718,77.046375'])
on conflict (slug) do update set
  title = excluded.title, city = excluded.city, location = excluded.location,
  description = excluded.description, preview_image_url = excluded.preview_image_url,
  route_images_urls = excluded.route_images_urls, completion_time = excluded.completion_time,
  distance = excluded.distance, elevation_gain_m = excluded.elevation_gain_m,
  max_elevation_m = excluded.max_elevation_m, difficulty = excluded.difficulty,
  is_verified = excluded.is_verified, verified_at = excluded.verified_at,
  verified_by = excluded.verified_by, path = excluded.path;

-- 4. BAL and Serkebay: photos are already in the app (assets/images/...).
--    TODO (BA): add verified coordinates, then set is_verified = true.
--    Until then they are NOT inserted. Template:
--
-- insert into public.routes
--   (slug, title, city, location, description, preview_image_url, route_images_urls,
--    completion_time, distance, elevation_gain_m, max_elevation_m, difficulty,
--    is_verified, verified_at, verified_by, path)
-- values
--   ('bal', 'Big Almaty Lake', 'Almaty', 'Big Almaty gorge', '...',
--    'assets/images/trail_bal.png', array['assets/images/trail_bal.png'],
--    <minutes>, <km>, <m>, <m>, '<easy|moderate|hard>',
--    true, '<yyyy-mm-dd>', '<name>', array['lat,lng', 'lat,lng', ...]);

-- Check:
select slug, title, city, distance, difficulty, is_verified, array_length(path, 1) as points
  from public.routes order by id;
