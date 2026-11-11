import 'dart:async';

import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when the trails could not be loaded because there is no
/// connection (offline, DNS failure, timeout).
class NoInternetException implements Exception {
  const NoInternetException();

  @override
  String toString() => 'No internet connection';
}

/// Where screens get trails from. Tests pass a fake implementation.
abstract interface class TrailsDataSource {
  /// Only verified trails (is_verified = true).
  Future<List<RouteModel>> getRoutes();

  /// [id] may be the numeric id or the slug (e.g. "karakungei") from a QR code.
  Future<RouteModel> getRouteById(String id);
}

final class RoutesRepository implements TrailsDataSource {
  RoutesRepository._();

  static final RoutesRepository _instance = RoutesRepository._();

  factory RoutesRepository() => _instance;

  static const _timeout = Duration(seconds: 15);

  final supabase = Supabase.instance.client;

  @override
  Future<List<RouteModel>> getRoutes() {
    return _guard(() async {
      final rawRoutes = await supabase
          .from('routes')
          .select()
          .eq('is_verified', true)
          .order('id')
          .timeout(_timeout);

      return rawRoutes.map(RouteModel.fromMap).toList();
    });
  }

  @override
  Future<RouteModel> getRouteById(String id) {
    return _guard(() async {
      final value = id.trim();
      final numericId = int.tryParse(value);

      final query = supabase.from('routes').select().eq('is_verified', true);
      final rawRoutes = await (numericId != null
              ? query.eq('id', numericId)
              : query.eq('slug', value))
          .limit(1)
          .timeout(_timeout);

      if (rawRoutes.isEmpty) {
        throw StateError('Trail "$value" not found');
      }
      return RouteModel.fromMap(rawRoutes.first);
    });
  }

  /// Turns network failures into [NoInternetException].
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on PostgrestException {
      rethrow; // the server answered -> not a connection problem
    } on TimeoutException {
      throw const NoInternetException();
    } catch (e) {
      if (isNetworkError(e)) throw const NoInternetException();
      rethrow;
    }
  }

  static bool isNetworkError(Object e) {
    final text = e.toString();
    return text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('XMLHttpRequest') ||
        text.contains('Failed to fetch') ||
        text.contains('Connection refused') ||
        text.contains('Connection closed') ||
        text.contains('Network is unreachable');
  }
}
