import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';

/// What happened with the last scanned QR code.
enum QrScreenState { idle, loading, found, notFound, noInternet }

class QrScreenController extends ChangeNotifier {
  QrScreenController({required this.repository});

  final TrailsDataSource repository;

  QrScreenState _state = QrScreenState.idle;

  QrScreenState get state => _state;

  RouteModel? _scannedRoute;

  /// The trail of the LAST scan only. It is null when the last scan failed,
  /// so an old trail is never opened by mistake (BUG-3).
  RouteModel? get scannedRoute => _scannedRoute;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  /// Looks up a trail by the text from the QR code (numeric id or slug).
  /// Returns the trail, or null if it was not found or there is no internet.
  Future<RouteModel?> getRouteById(String id) async {
    // Forget the previous scan before starting a new one (BUG-3).
    _scannedRoute = null;
    _errorMessage = '';
    _state = QrScreenState.loading;
    notifyListeners();

    try {
      final route = await repository.getRouteById(id.trim());
      _scannedRoute = route;
      _state = QrScreenState.found;
      return route;
    } on NoInternetException {
      _state = QrScreenState.noInternet;
      _errorMessage =
          'No internet connection. Check Wi-Fi or mobile data and try again.';
      return null;
    } catch (_) {
      // Unknown QR text, unverified trail or any other lookup error.
      _state = QrScreenState.notFound;
      _errorMessage = 'Route not found';
      return null;
    } finally {
      notifyListeners();
    }
  }
}
