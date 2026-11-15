# Sprint 3 · Пара 1 «Аккаунт и профиль»

Что умеет приложение после этой части:

- Приложение открывается **без входа** — маршруты, карта и QR доступны всем.
- Вкладка **Profile**: если не вошёл — экран «You are not signed in» с кнопкой **Sign In / Sign Up**.
- **Регистрация**: имя (необязательно), email, пароль, повтор пароля. Поля проверяются, ошибки понятные.
- **Вход**, **«Forgot password?»** (письмо со ссылкой для сброса пароля).
- После входа профиль показывает **аватар (или инициалы), имя, email, город**.
- **Personal information**: сменить фото, имя, город, пароль. Всё сохраняется в Supabase.
- **Sign Out** с подтверждением. Экран профиля сам обновляется при входе/выходе.

---

## 1. Запуск (один раз на проект Supabase)

1. Supabase → **SQL Editor** → New query → вставить `supabase/sprint3_profiles.sql` → **Run**.
   Внизу должна появиться таблица с профилями (по строке на каждого уже зарегистрированного).
2. Supabase → **Authentication → Sign In / Providers → Email**:
   - для разработки удобно **выключить «Confirm email»** — тогда после регистрации сразу входишь;
   - если оставить включённым — приложение покажет «We sent a confirmation link…», после подтверждения нужно войти.
3. Supabase → **Authentication → URL Configuration → Site URL** — сюда ведёт ссылка из письма «сброс пароля».
   Для учебного проекта можно оставить как есть: пользователь задаёт новый пароль по ссылке,
   либо (проще) входит и меняет пароль в **Personal information**.
4. В терминале, в папке `qaz-route-mobile-main`:
   ```
   flutter pub get
   flutter run --dart-define-from-file=supabase.env.json
   ```
   `flutter pub get` скачает новый пакет `image_picker` (выбор фото) и обновит `pubspec.lock`.
5. Автотесты: `flutter test` (новые — в `test/profile_test.dart`).

> Если меняете роуты (`app_router.dart`), перегенерируйте файл навигации:
> `dart run build_runner build --delete-conflicting-outputs`.
> Сейчас `app_router.gr.dart` уже обновлён вручную — запускать не обязательно.

---

## 2. Где что лежит

| Файл | Что делает | Аналог в iOS |
|------|------------|--------------|
| `supabase/sprint3_profiles.sql` | таблица `profiles`, триггер «создать профиль при регистрации», правила доступа (RLS), bucket `avatars` | — (это бэкенд) |
| `lib/src/model/profile_model.dart` | одна строка из `profiles` | `struct Profile: Codable` |
| `lib/src/repository/auth_repository.dart` | вход, регистрация, выход, сброс/смена пароля, `authErrorMessage()` | сервис `AuthService` |
| `lib/src/repository/profile_repository.dart` | загрузить / сохранить профиль, загрузить аватар | сервис `ProfileService` |
| `lib/src/core/validators.dart` | проверки email, пароля, длины текста | — |
| `lib/src/widget/auth_screen/…` | экран входа/регистрации + его controller | `View` + `ObservableObject` |
| `lib/src/widget/profile_screen/…` | вкладка Profile + controller (слушает вход/выход) | `View` + `ObservableObject` |
| `lib/src/widget/personal_info_screen/…` | экран редактирования профиля + controller | `View` + `ObservableObject` |
| `lib/src/widget/common/profile_avatar.dart` | круглый аватар (фото или инициалы) | переиспользуемый `View` |

**Как связаны части (на примере «сохранить имя»):**
`PersonalInfoScreen` (кнопка Save) → `PersonalInfoController.save()` → `ProfileRepository.updateProfile()` →
Supabase `update profiles set full_name = … where id = <мой id>` → новая строка возвращается →
controller вызывает `notifyListeners()` → экран перерисовывается.

**Почему чужой профиль не прочитать:** в SQL включён RLS — правило `auth.uid() = id`.
Даже если в приложении будет ошибка, база не отдаст чужую строку.

---

## 3. Как поделить работу внутри пары

Код уже написан — задача пары: **разобраться, запустить, проверить и защитить**.

| Человек A — «бэкенд и данные» | Человек B — «экраны» |
|---|---|
| Запустить `sprint3_profiles.sql`, проверить таблицу `profiles` и bucket `avatars` в Supabase | Разобрать `auth_screen.dart` и `profile_screen.dart` |
| Разобрать `profile_repository.dart` и `auth_repository.dart` | Разобрать `personal_info_screen.dart` |
| Проверить RLS: два аккаунта — каждый видит только себя (TC-09) | Пройти TC-04 … TC-08 на телефоне и в Chrome |
| Объяснить на защите: таблица, триггер, RLS, Storage | Объяснить на защите: экраны, controller, навигация |

Потом поменяйтесь и проверьте друг друга. Оба должны уметь рассказать путь «кнопка → controller → repository → Supabase».

---

## 4. Для Пары 2 («Мои маршруты»)

- id пользователя: `Supabase.instance.client.auth.currentUser?.id` (или `AuthRepository().currentUser?.id`).
- Свои таблицы (`favorites`, `completed_routes`) делайте с `user_id uuid references auth.users(id) on delete cascade`
  и такими же правилами RLS, как в `sprint3_profiles.sql` (`auth.uid() = user_id`).
- Свои разделы на экране профиля добавляйте в `profile_screen.dart` в место с комментарием
  `// ---------- Пара 2: сюда добавить разделы ----------`.
- Если пользователь не вошёл и нажал «сердечко» — открывайте вход: `context.router.push(const AuthRoute())`.

---

## 5. Тест-кейсы (ручные)

| ID | Priority | Module | Title |
|----|----------|--------|-------|
| TC-04 | 1 (Smoke) | Auth | Sign up with valid data |
| TC-05 | 1 (Smoke) | Auth | Sign in / Sign out |
| TC-06 | 2 (Functional) | Auth | Validation and wrong password |
| TC-07 | 2 (Functional) | Profile | Edit name and city |
| TC-08 | 2 (Functional) | Profile | Change avatar |
| TC-09 | 2 (Security) | Profile | User sees only own profile |
| TC-10 | 3 (Functional) | Auth | Forgot password |

### TC-04: Sign up with valid data
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Открыть приложение, вкладка Profile | «You are not signed in», кнопка Sign In / Sign Up |
| 2 | Нажать кнопку → «Sign Up» | Поля Name, Email, Password, Repeat password |
| 3 | Ввести имя, новый email, пароль ≥ 6 символов дважды, Sign Up | Confirm email выкл.: экран закрывается, в Profile имя и инициалы. Вкл.: зелёное сообщение «We sent a confirmation link…» |
| 4 | Supabase → Table Editor → `profiles` | Есть строка с этим email и именем |

### TC-05: Sign in / Sign out
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Profile → Sign In / Sign Up → ввести email и пароль из TC-04 → Sign In | Экран закрывается, показан профиль |
| 2 | Закрыть и снова открыть приложение | Пользователь всё ещё вошёл |
| 3 | Sign Out → подтвердить | Profile показывает «You are not signed in» |

### TC-06: Validation and wrong password
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Sign In с пустыми полями | Под полями «Enter your email», «Enter your password» |
| 2 | Email `abc`, пароль `123` | «Enter a valid email», «At least 6 characters» |
| 3 | Sign Up: пароли не совпадают | «Passwords do not match» |
| 4 | Sign In: верный email, неверный пароль | Красное сообщение «Wrong email or password.» |
| 5 | Sign Up: email, который уже есть | «An account with this email already exists…» |

### TC-07: Edit name and city
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Profile → Personal information | Поля Email (серое, нельзя менять), Name, City заполнены текущими данными |
| 2 | Изменить имя и город → Save | «Profile saved» |
| 3 | Назад | В Profile новое имя и город |
| 4 | Перезапустить приложение | Данные сохранились |

### TC-08: Change avatar
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Personal information → Change photo → выбрать фото | Крутилка на аватаре, затем «Photo updated» и новое фото |
| 2 | Назад | Фото в Profile |
| 3 | Supabase → Storage → `avatars` | Папка с id пользователя, внутри `avatar.jpg` |

### TC-09: User sees only own profile
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Войти пользователем A, задать имя «A» | Profile показывает «A» |
| 2 | Sign Out, войти пользователем B | Profile показывает данные B, не A |
| 3 | (A) SQL Editor: `set role authenticated; select * from profiles;` | Без входа строк нет — RLS работает |

### TC-10: Forgot password
| # | Step | Expected result |
|---|------|-----------------|
| 1 | Sign In → «Forgot password?» → ввести email → Send link | Зелёное сообщение «…a password reset link has been sent» |
| 2 | Проверить почту | Пришло письмо от Supabase со ссылкой |

Note: бесплатный Supabase отправляет ограниченное число писем в час — при «Too many attempts» подождите.
