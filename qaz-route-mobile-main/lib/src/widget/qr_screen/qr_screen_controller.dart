import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';

enum QrScreenState { loading, idle, error }

class QrScreenController extends ChangeNotifier {
  QrScreenController({required this.repository});

  final TrailsDataSource repository;

  QrScreenState _state = QrScreenState.idle;

  QrScreenState get state => _state;

  RouteModel? _scannedRoute;

  RouteModel? get scannedRoute => _scannedRoute;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  Future<void> getRouteById(String id) async {
    try {
      _state = QrScreenState.loading;
      notifyListeners();

      final route = await repository.getRouteById(id);
      _scannedRoute = route;

      _state = QrScreenState.idle;
    } catch (e) {
      _state = QrScreenState.error;
      _errorMessage = e is NoInternetException
          ? 'No internet connection'
          : 'Trail not found: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }
}
