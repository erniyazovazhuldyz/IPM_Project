import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/route_model.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/repository/saved_routes_repository.dart';

enum SavedRoutesState {
  /// Никто не вошёл — сохранять нельзя.
  signedOut,

  /// Грузим список.
  loading,

  /// Список загружен (может быть пустым).
  idle,

  error,
}

/// Что получилось после нажатия на «сердечко».
enum SaveToggleResult {
  saved,
  removed,

  /// Пользователь не вошёл — экран должен открыть вход.
  needsSignIn,

  /// Запрос не прошёл, сердечко вернулось как было.
  /// Текст ошибки — в [SavedRoutesController.lastErrorMessage].
  failed,

  /// Предыдущее нажатие на этот маршрут ещё обрабатывается.
  busy,
}

/// US-10: общие для всего приложения «мои сохранённые маршруты».
///
/// Один объект на всё приложение ([instance]), как MapFocus:
/// сердечко на экране маршрута и список в Profile слушают его,
/// поэтому всегда показывают одно и то же.
class SavedRoutesController extends ChangeNotifier {
  SavedRoutesController({
    required this.dataSource,
    required String? Function() currentUserId,
    Stream<String?>? userIdChanges,
  }) : _currentUserId = currentUserId {
    // Подписываемся на вход/выход: при входе грузим список, при выходе чистим.
    _authSubscription = userIdChanges?.listen(_onUserChanged);
    _onUserChanged(_currentUserId());
  }

  static SavedRoutesController? _instance;

  /// Настоящий контроллер (Supabase). В тестах создаётся свой через конструктор.
  static SavedRoutesController get instance {
    return _instance ??= SavedRoutesController(
      dataSource: SavedRoutesRepository(),
      currentUserId: () => AuthRepository().currentUser?.id,
      userIdChanges: AuthRepository().authStateChanges.map(
            (authState) => authState.session?.user.id,
          ),
    );
  }

  final SavedRoutesDataSource dataSource;
  final String? Function() _currentUserId;
  StreamSubscription<String?>? _authSubscription;

  /// Для какого пользователя загружен (или грузится) список.
  String? _loadedUserId;

  SavedRoutesState _state = SavedRoutesState.signedOut;

  SavedRoutesState get state => _state;

  List<RouteModel> _routes = [];

  /// Сохранённые маршруты, сначала новые.
  List<RouteModel> get routes => List.unmodifiable(_routes);

  final Set<String> _busyIds = {};

  String _errorMessage = '';

  /// Ошибка загрузки списка (для состояния [SavedRoutesState.error]).
  String get errorMessage => _errorMessage;

  String _lastErrorMessage = '';

  /// Ошибка последнего нажатия на сердечко (для SnackBar).
  String get lastErrorMessage => _lastErrorMessage;

  bool get isSignedIn => _currentUserId() != null;

  bool isSaved(String routeId) => _routes.any((r) => r.id == routeId);

  /// Идёт ли сейчас сохранение / удаление этого маршрута.
  bool isBusy(String routeId) => _busyIds.contains(routeId);

  void _onUserChanged(String? userId) {
    if (userId == null) {
      _loadedUserId = null;
      _routes = [];
      _busyIds.clear();
      _state = SavedRoutesState.signedOut;
      notifyListeners();
      return;
    }
    // Событие "обновился токен" приходит с тем же id — повторно не грузим.
    if (userId != _loadedUserId) {
      load();
    }
  }

  Future<void> load() async {
    final userId = _currentUserId();
    if (userId == null) {
      _onUserChanged(null);
      return;
    }

    _loadedUserId = userId;
    // Если список уже на экране (обновление) — не прячем его за крутилкой.
    if (_state != SavedRoutesState.idle) {
      _state = SavedRoutesState.loading;
      notifyListeners();
    }

    try {
      final loaded = await dataSource.getSavedRoutes();
      // Пока грузили, пользователь мог выйти или смениться.
      if (_currentUserId() != userId) return;
      _routes = loaded;
      _state = SavedRoutesState.idle;
    } catch (e) {
      if (_currentUserId() != userId) return;
      _loadedUserId = null; // чтобы "Try again" действительно попробовал снова
      _errorMessage = savedRoutesErrorMessage(e);
      _state = SavedRoutesState.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  /// Нажатие на сердечко: сохранить, если не сохранён, иначе убрать.
  ///
  /// Сердечко меняется СРАЗУ (не ждём ответа сервера), а если сервер
  /// ответил ошибкой — возвращается обратно.
  Future<SaveToggleResult> toggle(RouteModel route) async {
    if (!isSignedIn) return SaveToggleResult.needsSignIn;
    if (_busyIds.contains(route.id)) return SaveToggleResult.busy;

    final wasSaved = isSaved(route.id);
    final previous = List<RouteModel>.of(_routes);

    _busyIds.add(route.id);
    _lastErrorMessage = '';
    if (wasSaved) {
      _routes = _routes.where((r) => r.id != route.id).toList();
    } else {
      _routes = [route, ..._routes];
    }
    notifyListeners();

    try {
      if (wasSaved) {
        await dataSource.removeRoute(route.id);
        return SaveToggleResult.removed;
      } else {
        await dataSource.saveRoute(route.id);
        return SaveToggleResult.saved;
      }
    } catch (e) {
      _routes = previous; // откат
      _lastErrorMessage = savedRoutesErrorMessage(e);
      return SaveToggleResult.failed;
    } finally {
      _busyIds.remove(route.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
