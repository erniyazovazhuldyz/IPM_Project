-- QazRoute · Sprint 2 · verified trail: Furmanov Peak
-- Run in Supabase Dashboard -> SQL Editor -> New query -> Run.
-- Needs sprint2_migration.sql to be run first (columns slug, city, is_verified ...).
-- Safe to run again (upsert by slug).
insert into public.routes
  (slug, title, city, location, description,
   preview_image_url, route_images_urls,
   completion_time, distance, elevation_gain_m, max_elevation_m, difficulty,
   is_verified, verified_at, verified_by, path)
values
  ('furmanov-peak', 'Furmanov Peak', 'Almaty',
   'Medeu area, ridge east of the ice rink',
   'Classic summit hike from Medeu up the ridge to Furmanov Peak (~3050 m). '
   'Start: near the Medeu ice rink, 1651 m. '
   '7.2 km one way (~14.5 km round trip), +1432 m. 3.5-5 h to the summit, 6-8 h in total. '
   'Hard: long steep climb, start early and take plenty of water. In winter microspikes and warm gear are needed.',
   'assets/trails/furmanov_1.jpg',
   array['assets/trails/furmanov_1.jpg'],
   240, 7.2, 1432, 3080, 'hard',
   true, '2026-11-15', 'Sagdatova Alua (QA)',
   array['43.161043,77.055623', '43.161024,77.055377', '43.161391,77.055418', '43.160748,77.056066',
         '43.160376,77.056785', '43.160009,77.058255', '43.160124,77.059075', '43.160509,77.059195',
         '43.160956,77.05906', '43.161214,77.059385', '43.161845,77.063271', '43.16269,77.065631',
         '43.163466,77.066779', '43.165601,77.067994', '43.166028,77.068894', '43.166209,77.069683',
         '43.166165,77.070515', '43.165808,77.071662', '43.166219,77.072459', '43.166018,77.072594',
         '43.166219,77.0726', '43.166001,77.073066', '43.166008,77.073548', '43.165607,77.073834',
         '43.165363,77.074369', '43.164932,77.074767', '43.163891,77.075448', '43.163293,77.078124',
         '43.163384,77.078753', '43.163859,77.079683', '43.16399,77.080452', '43.163834,77.081098',
         '43.163823,77.08273', '43.164522,77.08405', '43.164569,77.08472', '43.164761,77.085113',
         '43.164854,77.088122', '43.164595,77.088849', '43.164219,77.089013', '43.163434,77.088893',
         '43.16311,77.088687', '43.162913,77.088206', '43.162675,77.088176', '43.162429,77.087706',
         '43.162052,77.087555', '43.162279,77.088253', '43.162329,77.089931', '43.162502,77.090515',
         '43.162287,77.091468', '43.162498,77.092593', '43.162304,77.093037', '43.162506,77.093032',
         '43.162416,77.093381', '43.162632,77.093531', '43.162813,77.096647', '43.162589,77.097287',
         '43.162051,77.098006', '43.161684,77.099422', '43.161664,77.100013', '43.161303,77.100931',
         '43.160147,77.102325', '43.159163,77.10443', '43.158414,77.105506', '43.157885,77.10697',
         '43.157956,77.107204', '43.157715,77.107369', '43.156373,77.109975', '43.156008,77.110289',
         '43.155826,77.111407', '43.155326,77.112805', '43.155466,77.114083', '43.155682,77.114098',
         '43.155597,77.11454', '43.154968,77.114576', '43.154648,77.114812', '43.153695,77.114454',
         '43.152862,77.11462', '43.152582,77.115038', '43.150473,77.114995', '43.15002,77.115365',
         '43.149837,77.115752'])
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
  from public.routes where slug = 'furmanov-peak';
