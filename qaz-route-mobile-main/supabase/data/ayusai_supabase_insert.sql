-- QazRoute · Sprint 2 · verified trail: Ayusai Waterfalls
-- Run in Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Needs sprint2_migration.sql to be run first (columns slug, city, is_verified ...).
-- Safe to run again (upsert by slug).
insert into public.routes
  (slug, title, city, location, description,
   preview_image_url, route_images_urls,
   completion_time, distance, elevation_gain_m, max_elevation_m, difficulty,
   is_verified, verified_at, verified_by, path)
values
  ('ayusai', 'Ayusai Waterfalls', 'Almaty',
   'Ile-Alatau National Park, Ayusai gorge',
   'Trail up the Ayusai gorge to its waterfalls, along the stream. '
   'Start: lower end of the gorge trail, 1671 m. '
   '2.2 km one way (~4.4 km round trip), +324 m. 1-1.5 h to the upper waterfall, 2-2.5 h in total. '
   'Moderate: steady climb on a rocky path. Best from late spring to autumn; icy in winter.',
   'assets/trails/ayusai_1.jpg',
   array['assets/trails/ayusai_1.jpg'],
   90, 2.2, 324, 1998, 'moderate',
   true, '2026-11-15', 'Sagdatova Alua (QA)',
   array['43.101132,76.944365', '43.100983,76.944191', '43.100827,76.943773', '43.100544,76.943869',
         '43.10034,76.943648', '43.100097,76.943685', '43.099733,76.944017', '43.099421,76.943819',
         '43.099324,76.943595', '43.098887,76.943563', '43.098673,76.943419', '43.097592,76.94355',
         '43.097095,76.943251', '43.096584,76.94343', '43.096449,76.943394', '43.096409,76.943609',
         '43.096203,76.94389', '43.096082,76.943829', '43.096086,76.94402', '43.095918,76.944229',
         '43.095927,76.944474', '43.095799,76.944825', '43.095473,76.945177', '43.095329,76.945599',
         '43.094891,76.946402', '43.0948,76.946837', '43.094387,76.94762', '43.093865,76.948152',
         '43.093613,76.948027', '43.093749,76.947972', '43.093633,76.948114', '43.093399,76.948132',
         '43.093237,76.94827', '43.093054,76.948273', '43.093007,76.94811', '43.092891,76.948195',
         '43.0928,76.948067', '43.092325,76.948039', '43.092035,76.948133', '43.091693,76.947926',
         '43.091256,76.947963', '43.090584,76.947782', '43.090512,76.947858', '43.090272,76.947777',
         '43.090058,76.947521', '43.089742,76.947541', '43.089252,76.947166', '43.089172,76.947008',
         '43.088999,76.947004', '43.088812,76.946848', '43.088671,76.946622', '43.088259,76.946561',
         '43.088102,76.946722', '43.088058,76.946481', '43.0881,76.946504', '43.088065,76.946667',
         '43.088063,76.94652', '43.087955,76.946577', '43.087885,76.946355', '43.087651,76.94638',
         '43.0874,76.946182', '43.08725,76.94617', '43.087133,76.945831', '43.08717,76.945599',
         '43.086929,76.945341', '43.086937,76.945064', '43.087031,76.945088', '43.086956,76.94525',
         '43.086859,76.945117'])
on conflict (slug) do update set
  title = excluded.title, city = excluded.city, location = excluded.location,
  description = excluded.description, preview_image_url = excluded.preview_image_url,
  route_images_urls = excluded.route_images_urls, completion_time = excluded.completion_time,
  distance = excluded.distance, elevation_gain_m = excluded.elevation_gain_m,
  max_elevation_m = excluded.max_elevation_m, difficulty = excluded.difficulty,
  is_verified = excluded.is_verified, verified_at = excluded.verified_at,
  verified_by = excluded.verified_by, path = excluded.path;

-- Check:
select slug, title, distance, difficulty, is_verified, array_length(path, 1) as points
  from public.routes where slug = 'ayusai';
