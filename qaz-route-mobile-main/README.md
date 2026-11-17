# QazRoute mobile (Flutter)

## Run in VS Code
1. Install Flutter SDK + VS Code extensions "Flutter" and "Dart". Check: `flutter doctor`.
2. Open THIS folder (`qaz-route-mobile-main`) in VS Code.
3. Terminal:
   ```
   flutter clean
   flutter pub get
   ```
4. New Supabase: copy `supabase.env.example.json` -> `supabase.env.json`, paste your Project URL and anon key.
5. Pick a device (bottom-right in VS Code: Android emulator / phone / Chrome).
6. Run and Debug (Ctrl+Shift+D) -> "QazRoute (NEW Supabase)" or "QazRoute (OLD Supabase)" -> F5.

Terminal alternative:
```
flutter run --dart-define-from-file=supabase.env.json
```

## New Supabase setup
1. supabase.com -> New project.
2. SQL Editor -> run `supabase/schema.sql`.
3. Authentication -> Sign In / Providers -> Email: on. For testing turn off "Confirm email".
4. Project Settings -> API: copy Project URL and anon public key into `supabase.env.json`.

## Sprint 2 update
1. Supabase → SQL Editor → run `supabase/sprint2_migration.sql`
   (adds `is_verified`, `city`, `difficulty`… and the verified Karakungei trail).
2. `flutter pub get` → `flutter run -d chrome --dart-define-from-file=supabase.env.json`
3. Automated tests for TC-01…TC-03: `flutter test` (see `docs/test_cases.md`).

Trail photos are bundled in `assets/` (`assets/trails`, `assets/images`), so
`preview_image_url` can be either `assets/...` or a normal `https://` link.
Raw BA data (GPX, GeoJSON, CSV) is in `supabase/data/`.

## Sprint 3 update (Pair 1: account & profile)
1. Supabase → SQL Editor → run `supabase/sprint3_profiles.sql`
   (table `profiles`, auto-create profile on sign up, RLS, Storage bucket `avatars`).
2. `flutter pub get` (new package `image_picker`) → `flutter run --dart-define-from-file=supabase.env.json`
3. Tests: `flutter test` (`test/profile_test.dart`).

Details, file map, manual test cases TC-04…TC-10 (in Russian): `docs/sprint3_pair1.md`.

## US-10 update (Saved routes)
1. Supabase → SQL Editor → run `supabase/us10_saved_routes.sql`
   (table `saved_routes`, RLS: each user sees only own saved trails).
2. `flutter pub get` → `flutter run --dart-define-from-file=supabase.env.json`
3. Tests: `flutter test test/saved_routes_test.dart`.

Details, file map, manual test cases TC-11…TC-15 (in Russian): `docs/us10_saved_routes.md`.
