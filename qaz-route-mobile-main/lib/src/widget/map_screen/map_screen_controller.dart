import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';

enum MapScreenState { loading, idle, error }

class MapScreenController extends ChangeNotifier {
  MapScreenController({required this.repository});

  final TrailsDataSource repository;

  List<RouteModel> _routes = [];

  List<RouteModel> get routes => _routes;

  MapScreenState _state = MapScreenState.idle;

  MapScreenState get state => _state;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  RouteModel? _selectedRoute;

  RouteModel? get selectedRoute => _selectedRoute;

  Future<void> loadRoutes() async {
    try {
      _state = MapScreenState.loading;
      notifyListeners();

      _routes = await repository.getRoutes();
      _state = MapScreenState.idle;
    } catch (e) {
      _state = MapScreenState.error;
      _errorMessage = 'Failed to load routes: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  /// Tap a marker: show its route line and preview card.
  /// Tap the same marker again: hide them.
  void selectRoute(RouteModel route) {
    _selectedRoute = _selectedRoute?.id == route.id ? null : route;
    notifyListeners();
  }
}
