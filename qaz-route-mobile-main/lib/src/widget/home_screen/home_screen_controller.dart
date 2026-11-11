import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/routes_repository.dart';

enum HomeScreenState { loading, idle, noInternet, error }

class HomeScreenController extends ChangeNotifier {
  HomeScreenController({required this.repository});

  final TrailsDataSource repository;

  HomeScreenState _state = HomeScreenState.idle;

  HomeScreenState get state => _state;

  List<RouteModel> _routes = [];

  /// All verified trails loaded from the backend.
  List<RouteModel> get allRoutes => List.unmodifiable(_routes);

  /// Verified trails after search and difficulty filter.
  List<RouteModel> get routes => _routes.where((route) {
        final matchesSearch = _searchQuery.isEmpty ||
            route.title.toLowerCase().contains(_searchQuery) ||
            route.displayCity.toLowerCase().contains(_searchQuery);
        final matchesDifficulty = _difficulty == null ||
            route.difficulty?.toLowerCase() == _difficulty;
        return matchesSearch && matchesDifficulty;
      }).toList();

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  String? _difficulty;

  /// null = all difficulties.
  String? get difficulty => _difficulty;

  /// Difficulties that exist in the loaded trails, e.g. [easy, moderate].
  List<String> get availableDifficulties {
    final set = <String>{
      for (final r in _routes)
        if (r.difficulty != null && r.difficulty!.isNotEmpty)
          r.difficulty!.toLowerCase(),
    };
    const order = ['easy', 'moderate', 'medium', 'hard'];
    return set.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
  }

  bool get hasActiveFilter => _searchQuery.isNotEmpty || _difficulty != null;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  Future<void> loadRoutes() async {
    try {
      _state = HomeScreenState.loading;
      notifyListeners();

      final loaded = await repository.getRoutes();
      // Double safety: never show unverified trails (TC-02).
      _routes = loaded.where((route) => route.isVerified).toList();
      _state = HomeScreenState.idle;
    } on NoInternetException {
      _state = HomeScreenState.noInternet;
    } catch (e) {
      _state = HomeScreenState.error;
      _errorMessage = 'Failed to load trails: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshRoutes() async {
    await loadRoutes();
  }

  void searchRoutes(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setDifficulty(String? difficulty) {
    _difficulty = difficulty?.toLowerCase();
    notifyListeners();
  }
}
