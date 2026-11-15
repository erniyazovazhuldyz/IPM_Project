import 'dart:async';

import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Результат регистрации.
enum SignUpResult {
  /// Аккаунт создан, пользователь сразу вошёл.
  signedIn,

  /// Аккаунт создан, но в Supabase включено "Confirm email":
  /// пользователь должен открыть письмо и подтвердить почту, потом войти.
  needsEmailConfirmation,
}

/// Всё, что связано со входом/выходом. Экраны НЕ обращаются к Supabase
/// напрямую — только через этот класс (как сервисный слой в iOS).
class AuthRepository {
  AuthRepository._();

  static final AuthRepository _instance = AuthRepository._();

  factory AuthRepository() => _instance;

  final supabase = Supabase.instance.client;

  /// Поток событий: вошёл / вышел / обновился токен.
  /// Экран профиля подписывается на него и перерисовывается сам.
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  Future<User?> signIn({
    required String password,
    required String email,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      password: password,
      email: email.trim(),
    );

    return response.user;
  }

  /// [fullName] сохраняется в metadata, а SQL-триггер (sprint3_profiles.sql)
  /// переносит его в таблицу profiles.
  Future<SignUpResult> signUp({
    required String password,
    required String email,
    String? fullName,
  }) async {
    final response = await supabase.auth.signUp(
      password: password,
      email: email.trim(),
      data: {
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
      },
    );

    // Если сессии нет — значит Supabase ждёт подтверждения email.
    return response.session == null
        ? SignUpResult.needsEmailConfirmation
        : SignUpResult.signedIn;
  }

  /// Отправляет письмо со ссылкой для сброса пароля.
  Future<void> sendPasswordReset(String email) async {
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  /// Смена пароля для уже вошедшего пользователя.
  Future<void> changePassword(String newPassword) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<User?> getUser() async {
    return supabase.auth.currentUser;
  }

  /// Есть ли сохранённая сессия. Истёкший токен supabase обновляет сам,
  /// поэтому достаточно проверить, что сессия вообще есть.
  bool isAuthenticated() {
    return supabase.auth.currentSession != null;
  }
}

/// Превращает ошибку Supabase в понятный пользователю текст
/// (вместо "AuthApiException(message: ..., statusCode: 400)").
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    final code = error.code ?? '';

    if (error is AuthRetryableFetchException ||
        RoutesRepository.isNetworkError(error)) {
      return 'No internet connection. Check your network and try again.';
    }
    if (code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return 'Wrong email or password.';
    }
    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return 'Please confirm your email first — check your inbox.';
    }
    if (code == 'user_already_exists' ||
        code == 'email_exists' ||
        message.contains('already registered')) {
      return 'An account with this email already exists. Try signing in.';
    }
    if (error is AuthWeakPasswordException ||
        code == 'weak_password' ||
        message.contains('password should be')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (code == 'same_password' || message.contains('different from the old')) {
      return 'New password must be different from the old one.';
    }
    if (code == 'over_email_send_rate_limit' ||
        code == 'over_request_rate_limit' ||
        message.contains('rate limit') ||
        error.statusCode == '429') {
      return 'Too many attempts. Please wait a minute and try again.';
    }
    if (code == 'email_address_invalid' || message.contains('invalid email')) {
      return 'This email address looks invalid.';
    }
    return error.message;
  }

  if (error is NoInternetException ||
      error is TimeoutException ||
      RoutesRepository.isNetworkError(error)) {
    return 'No internet connection. Check your network and try again.';
  }

  return 'Something went wrong. Please try again.';
}
