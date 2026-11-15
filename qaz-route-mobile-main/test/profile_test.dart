// Sprint 3, Пара 1: автотесты для профиля и входа (без сети и без Supabase).
// docs/sprint3_pair1.md: TC-04 … TC-10 — ручные тесты на телефоне.
//
// Run:  flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:qaz_route_mobile/src/core/validators.dart';
import 'package:qaz_route_mobile/src/model/profile_model.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('  user@mail.kz  '), isNull);
    });

    test('password: at least 6 characters', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });

    test('confirm password must match', () {
      final validator = Validators.confirmPassword(() => 'secret1');
      expect(validator('secret2'), 'Passwords do not match');
      expect(validator('secret1'), isNull);
    });

    test('optional text: empty ok, too long not ok', () {
      final validator = Validators.optionalText(max: 5);
      expect(validator(''), isNull);
      expect(validator('Aruzhan'), isNotNull);
    });
  });

  group('ProfileModel', () {
    test('fromMap reads a profiles row', () {
      final profile = ProfileModel.fromMap({
        'id': 'u1',
        'email': 'aya@mail.kz',
        'full_name': 'Ayaulym Raimbek',
        'city': 'Almaty',
        'avatar_url': null,
        'created_at': '2026-11-15T10:00:00Z',
      });
      expect(profile.displayName, 'Ayaulym Raimbek');
      expect(profile.initials, 'AR');
      expect(profile.hasAvatar, isFalse);
      expect(profile.city, 'Almaty');
      expect(profile.createdAt, isNotNull);
    });

    test('without a name shows email and its first letter', () {
      const profile = ProfileModel(id: 'u2', email: 'dana@mail.kz');
      expect(profile.hasName, isFalse);
      expect(profile.displayName, 'dana@mail.kz');
      expect(profile.initials, 'D');
    });

    test('works with Kazakh / Russian names', () {
      const profile = ProfileModel(id: 'u3', fullName: 'Әлия Серікова');
      expect(profile.initials, 'ӘС');
    });
  });

  group('authErrorMessage', () {
    test('wrong password', () {
      final e = AuthException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );
      expect(authErrorMessage(e), 'Wrong email or password.');
    });

    test('email already registered', () {
      final e = AuthException('User already registered', statusCode: '422');
      expect(authErrorMessage(e), contains('already exists'));
    });

    test('no internet', () {
      expect(
        authErrorMessage(const NoInternetException()),
        contains('No internet'),
      );
    });

    test('unknown error does not show technical text', () {
      expect(
        authErrorMessage(Exception('boom')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
