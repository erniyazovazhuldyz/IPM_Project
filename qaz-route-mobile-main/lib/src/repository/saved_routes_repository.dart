import 'dart:async';

import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/profile_repository.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// US-10: откуда экраны берут сохранённые маршруты.
/// В тестах подставляется фейковая версия (test/saved_routes_test.dart).
abstract interface class SavedRoutesDataSource {
  /// Сохранённые маршруты текущего пользователя, сначала новые.
  Future<List<RouteModel>> getSavedRoutes();

  /// Сохранить маршрут. Повторное сохранение — не ошибка.
  Future<void> saveRoute(String routeId);

  /// Убрать маршрут из сохранённых.
  Future<void> removeRoute(String routeId);
}

/// Работает с таблицей public.saved_routes (supabase/us10_saved_routes.sql).
final class SavedRoutesRepository implements SavedRoutesDataSource {
  SavedRoutesRepository._();

  static final SavedRoutesRepository _instance = SavedRoutesRepository._();

  factory SavedRoutesRepository() => _instance;

  static const _timeout = Duration(seconds: 15);
  static const _table = 'saved_routes';

  final supabase = Supabase.instance.client;

  User get _user {
    final user = supabase.auth.currentUser;
    if (user == null) throw const NotSignedInException();
    return user;
  }

  @override
  Future<List<RouteModel>> getSavedRoutes() {
    return _guard(() async {
      final user = _user;
      // routes(*) — Supabase сам подтягивает строку маршрута по route_id
      // (связь через foreign key, как JOIN в SQL).
      final rows = await supabase
          .from(_table)
          .select('created_at, routes(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .timeout(_timeout);

      return rows
          .map((row) => row['routes'])
          .whereType<Map<String, dynamic>>()
          .map(RouteModel.fromMap)
          // Непроверенные маршруты нигде в приложении не показываем (TC-02).
          .where((route) => route.isVerified)
          .toList();
    });
  }

  @override
  Future<void> saveRoute(String routeId) {
    return _guard(() async {
      final user = _user;
      // ignoreDuplicates: если маршрут уже сохранён — ничего не делаем,
      // ошибки "duplicate key" не будет.
      await supabase
          .from(_table)
          .upsert(
            {'user_id': user.id, 'route_id': _toDbId(routeId)},
            onConflict: 'user_id,route_id',
            ignoreDuplicates: true,
          )
          .timeout(_timeout);
    });
  }

  @override
  Future<void> removeRoute(String routeId) {
    return _guard(() async {
      final user = _user;
      await supabase
          .from(_table)
          .delete()
          .eq('user_id', user.id)
          .eq('route_id', _toDbId(routeId))
          .timeout(_timeout);
    });
  }

  /// В приложении id маршрута — строка ("12"), в базе — число (bigint).
  static int _toDbId(String routeId) => int.parse(routeId);

  /// Сетевые ошибки -> [NoInternetException] (как в других репозиториях).
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException {
      rethrow;
    } on NotSignedInException {
      rethrow;
    } on TimeoutException {
      throw const NoInternetException();
    } catch (e) {
      if (RoutesRepository.isNetworkError(e)) throw const NoInternetException();
      rethrow;
    }
  }
}

/// Понятный текст ошибки для экранов с сохранёнными маршрутами.
String savedRoutesErrorMessage(Object error) {
  if (error is NoInternetException) {
    return 'No internet connection. Check your network and try again.';
  }
  if (error is NotSignedInException) {
    return 'Sign in to save routes.';
  }
  if (error is PostgrestException) {
    // 42P01 / PGRST205 = таблицы нет -> забыли запустить миграцию
    if (error.code == '42P01' ||
        error.code == 'PGRST205' ||
        error.code == 'PGRST200' ||
        error.message.contains('schema cache')) {
      return 'Saved routes are not set up yet. '
          'Run supabase/us10_saved_routes.sql in Supabase.';
    }
    return 'Server error: ${error.message}';
  }
  return 'Something went wrong. Please try again.';
}
