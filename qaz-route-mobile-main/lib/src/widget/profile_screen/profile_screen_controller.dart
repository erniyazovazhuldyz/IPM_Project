import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/model/profile_model.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:qaz_route_mobile/src/repository/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ProfileScreenState {
  /// Грузим профиль.
  loading,

  /// Никто не вошёл — показываем приглашение войти.
  signedOut,

  /// Профиль загружен.
  idle,

  error,
}

class ProfileScreenController extends ChangeNotifier {
  ProfileScreenController({
    required this.authRepository,
    required this.profileRepository,
  });

  final AuthRepository authRepository;
  final ProfileDataSource profileRepository;

  StreamSubscription<AuthState>? _authSubscription;

  /// Для какого пользователя уже загружен (или грузится) профиль —
  /// чтобы не грузить его повторно на каждое событие (например, обновление токена).
  String? _loadedUserId;

  ProfileScreenState _state = ProfileScreenState.loading;

  ProfileScreenState get state => _state;

  ProfileModel? _profile;

  ProfileModel? get profile => _profile;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  /// Вызывается один раз из initState экрана.
  /// Подписываемся на вход/выход: экран обновится сам, без перезапуска.
  void start() {
    if (authRepository.isAuthenticated()) {
      loadProfile();
    } else {
      _state = ProfileScreenState.signedOut;
      notifyListeners();
    }
    _authSubscription = authRepository.authStateChanges.listen(
      _onAuthStateChanged,
    );
  }

  void _onAuthStateChanged(AuthState authState) {
    final user = authState.session?.user;

    if (user == null) {
      _loadedUserId = null;
      _profile = null;
      _state = ProfileScreenState.signedOut;
      notifyListeners();
      return;
    }

    if (user.id != _loadedUserId) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    final user = authRepository.currentUser;
    if (user == null) {
      _state = ProfileScreenState.signedOut;
      notifyListeners();
      return;
    }

    _loadedUserId = user.id;
    // Если профиль уже есть на экране (обновление) — не прячем его за крутилкой.
    if (_profile == null) {
      _state = ProfileScreenState.loading;
      notifyListeners();
    }

    try {
      final loaded = await profileRepository.getMyProfile();
      // Пока грузили, пользователь мог выйти — тогда результат не нужен.
      if (authRepository.currentUser?.id != user.id) return;
      _profile = loaded;
      _state = ProfileScreenState.idle;
    } catch (e) {
      if (authRepository.currentUser?.id != user.id) return;
      _loadedUserId = null; // чтобы "Retry" действительно попробовал снова
      _state = ProfileScreenState.error;
      _errorMessage = profileErrorMessage(e);
    }
    notifyListeners();
  }

  Future<void> refresh() => loadProfile();

  Future<bool> signOut() async {
    try {
      await authRepository.signOut();
      // Состояние signedOut выставит _onAuthStateChanged.
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
