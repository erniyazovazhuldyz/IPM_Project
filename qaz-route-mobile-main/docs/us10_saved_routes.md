# US-10 · Сохранение маршрутов (Saved routes)

Из TSIS 6–7: **Should**, Release 2 (Sprint 4), 3 SP, зависит от US-09 (вход).

**User story:** As a **registered user**, I want to **save a trail with the heart icon**, so that **I can open it quickly next time**.

| Given | When | Then |
|-------|------|------|
| I am logged in and see a trail card | I tap the heart icon | The trail appears in "My routes" in my profile, also after I restart the app |

Что умеет приложение после этой части:

- «Сердечко» ♡ на каждой **карточке маршрута** на Home и справа вверху на экране **Route Details**.
- Нажал — маршрут сохранён (♥), нажал ещё раз — убран. Сердечки на Home, в деталях и в Profile всегда совпадают.
- Если не вошёл — открывается экран входа, после входа маршрут сохраняется сам.
- В **Profile** раздел **MY ROUTES**: фото, название, город · км · сложность. Нажал — открывается маршрут. ♥ справа — убрать.
- Сохранено в Supabase, поэтому остаётся после перезапуска приложения и на другом телефоне.
- Пусто — подсказка «No saved routes yet…». Нет интернета — сердечко возвращается назад и показывается ошибка.
- Каждый видит только свои сохранённые маршруты (RLS в Supabase).

-------|------|------|
| I am signed in and open a verified trail | I tap ♡ on the Route Details screen | The heart fills, "Route saved" appears, and the trail is listed in Profile → Saved routes |

Что умеет приложение после этой части:

- На экране **Route Details** справа вверху «сердечко» ♡.
- Нажал — маршрут сохранён (♥), нажал ещё раз — убран.
- Если не вошёл — открывается экран входа, после входа маршрут сохраняется сам.
- В **Profile** раздел **SAVED ROUTES**: фото, название, город · км · сложность. Нажал — открывается маршрут. ♥ справа — убрать.
- Пусто — подсказка «No saved routes yet…». Нет интернета — сердечко возвращается назад и показывается ошибка.
- Каждый видит только свои сохранённые маршруты (RLS в Supabase).

---

## 1. Запуск (один раз на проект Supabase)

1. Должны быть уже запущены `schema.sql`, `sprint2_migration.sql`, `sprint3_profiles.sql`.
2. Supabase → **SQL Editor** → New query → вставить `supabase/us10_saved_routes.sql` → **Run**.
   Внизу появится пустая таблица (route_id, title…) — это нормально.
3. В терминале, в папке `qaz-route-mobile-main`:
   ```
   flutter pub get
   flutter analyze
   flutter test
   flutter run --dart-define-from-file=supabase.env.json
   ```
   Новых пакетов нет.

---

## 2. Где что лежит

| Файл | Что делает |
|------|------------|
| `supabase/us10_saved_routes.sql` | таблица `saved_routes` (user_id + route_id), правила доступа RLS |
| `lib/src/repository/saved_routes_repository.dart` | загрузить / сохранить / убрать маршрут в Supabase, понятные тексты ошибок |
| `lib/src/widget/saved_routes/saved_routes_controller.dart` | общий для всего приложения список сохранённых; сам обновляется при входе/выходе |
| `lib/src/widget/saved_routes/save_route_button.dart` | «сердечко» (карточка на Home и экран маршрута) |
| `lib/src/widget/saved_routes/saved_routes_section.dart` | раздел MY ROUTES в Profile |
| `lib/src/widget/home_screen/home_screen.dart` | сердечко справа на карточке маршрута |
| `lib/src/widget/route_details_screen/route_details_screen.dart` | добавлено сердечко в AppBar (`actions`) |
| `lib/src/widget/profile_screen/profile_screen.dart` | добавлен раздел + обновление потягиванием вниз |
| `test/saved_routes_test.dart` | автотесты (без сети) |

**Путь «нажал сердечко»:**
`SaveRouteButton` → `SavedRoutesController.toggle()` (сердечко меняется сразу) →
`SavedRoutesRepository.saveRoute()` → Supabase `insert into saved_routes (user_id, route_id)` →
ошибка? — откат и SnackBar. Раздел в Profile слушает тот же контроллер и обновляется сам.

---

## 3. Тест-кейсы (ручные)

| ID | Priority | Module | Title |
|----|----------|--------|-------|
| TC-11 | 1 (Smoke) | Saved routes | Save and unsave a trail |
| TC-12 | 2 (Functional) | Saved routes | Saved trail in Profile, opens details |
| TC-13 | 2 (Functional) | Saved routes | Not signed in → sign in → trail saved |
| TC-14 | 2 (Security) | Saved routes | User sees only own saved trails |
| TC-15 | 3 (Functional) | Saved routes | No internet while saving |

### TC-11: Save and unsave a trail
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Войти, вкладка Home | На карточке Karakungei справа пустое ♡ |
| 2 | Нажать ♡ на карточке | ♥ заполнено, «Route saved. Find it in Profile → My routes.» |
| 3 | Supabase → Table Editor → `saved_routes` | Строка с вашим user_id и route_id Karakungei |
| 4 | Открыть Karakungei | В деталях справа вверху тоже ♥ |
| 5 | Нажать ♥ ещё раз | ♡ пустое, «Removed from saved routes.», строка в таблице удалена; на карточке Home тоже ♡ |

### TC-12: Saved trail in Profile, opens details
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Сохранить Karakungei (TC-11, шаги 1–2) | ♥ |
| 2 | Вкладка Profile | Раздел MY ROUTES: фото, «Karakungei», «Almaty · 1.5 km · Easy» |
| 3 | Нажать на маршрут | Открывается Route Details этого маршрута, ♥ заполнено |
| 4 | Перезапустить приложение → Profile | Маршрут всё ещё в списке |

### TC-13: Not signed in → sign in → trail saved
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Выйти (Profile → Sign Out), на Home нажать ♡ на карточке | «Sign in to save routes.», открывается экран входа |
| 2 | Войти | Возврат на Home, ♥ заполнено, «Route saved…» |

### TC-14: User sees only own saved trails
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Пользователь A сохраняет Karakungei | В Profile A маршрут есть |
| 2 | Sign Out, войти пользователем B | MY ROUTES пусто: «No saved routes yet…» |
| 3 | Снова войти A | Karakungei на месте |

### TC-15: No internet while saving
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Открыть Home, выключить Wi-Fi и мобильный интернет | — |
| 2 | Нажать ♡ | ♥ на секунду, затем снова ♡ и «No internet connection…» |
| 3 | Включить интернет, нажать ♡ | Маршрут сохранён |

Автотесты тех же сценариев: `flutter test test/saved_routes_test.dart`.
