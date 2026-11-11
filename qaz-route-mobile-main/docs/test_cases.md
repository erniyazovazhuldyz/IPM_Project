# QazRoute: Sprint 2 test cases (Home screen)

Automated versions: `test/home_screen_test.dart` (run `flutter test`).
Manual runs: on a real phone and in Chrome (`flutter run -d chrome --dart-define-from-file=supabase.env.json`).

| ID | Priority | Requirement | Module | Title | Auto test |
|----|----------|-------------|--------|-------|-----------|
| TC-01 | 1 (Smoke) | US-01 | Home Screen | Display Verified Trail | `TC-01 Display verified trail (photo, name, city)` |
| TC-02 | 2 (Functional) | US-01 | Home Screen | Hide Unverified Trail | `TC-02 Hide unverified trail` |
| TC-03 | 2 (Functional) | US-01 | Home Screen | No Internet and Retry | `TC-03 No internet, then Try again loads the trail` |

---

## TC-01: Display Verified Trail
**Priority:** 1 (Smoke) · **Requirement:** US-01 · **Module:** Home Screen

| # | Test step | Expected result |
|---|-----------|-----------------|
| 1 | Launch the QazRoute application. | The application opens successfully. |
| 2 | Open the Home screen. | The Home screen is displayed. |
| 3 | Locate the "Popular locations" section. | The "Popular locations" section is visible. |
| 4 | Check the BAL trail card. | The verified BAL trail is displayed with the correct photo, name, and city. |

## TC-02: Hide Unverified Trail
**Priority:** 2 (Functional) · **Requirement:** US-01 · **Module:** Home Screen

| # | Test step | Expected result |
|---|-----------|-----------------|
| 1 | Launch the QazRoute application. | The application opens successfully. |
| 2 | Open the Home screen. | The Home screen is displayed. |
| 3 | Locate the "Popular locations" section. | The "Popular locations" section is visible, and the verified BAL trail is displayed. |
| 4 | Check whether the unverified test trail appears in the list. | The unverified test trail is not displayed in the list. |

Test data: row `TEST - Medeu to Shymbulak` in `routes` has `is_verified = false`.

## TC-03: No Internet and Retry
**Priority:** 2 (Functional) · **Requirement:** US-01 · **Module:** Home Screen

| # | Test step | Expected result |
|---|-----------|-----------------|
| 1 | Disable Wi-Fi and mobile data. | The device has no internet connection. |
| 2 | Launch the QazRoute application. | The application opens successfully. |
| 3 | Open the Home screen. | The "No internet connection" message and "Try again" button are displayed instead of empty trail cards. |
| 4 | Enable Wi-Fi or mobile data. | The internet connection is restored. |
| 5 | Tap the "Try again" button. | The verified BAL trail is loaded and displayed on the Home screen. |

Note: in Chrome you can simulate step 1 via DevTools → Network → "Offline".

---

## Test data status
| Trail | Photo in app | Coordinates | is_verified |
|-------|--------------|-------------|-------------|
| Karakungei | `assets/trails/karakungei_1.jpg`, `_2.jpg` | 34 points (BA, 2026-10-20) | true |
| BAL (Big Almaty Lake) | `assets/images/trail_bal.png` | **TODO** | not inserted yet |
| Serkebay | `assets/images/trail_serkebay.png` | **TODO** | not inserted yet |
| TEST - Medeu to Shymbulak | placeholder | approximate | false (for TC-02) |

TC-01 and TC-03 on the real backend need the BAL row in Supabase
(template at the end of `supabase/sprint2_migration.sql`).
Until then, run them against Karakungei.
