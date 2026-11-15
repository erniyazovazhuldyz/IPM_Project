import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';

enum AuthScreenState { loading, idle, error }

/// "ViewModel" экрана входа (как ObservableObject в SwiftUI).
/// notifyListeners() == @Published: экран перерисовывается.
class AuthScreenController extends ChangeNotifier {
  AuthScreenController({required this.repository});

  final AuthRepository repository;

  AuthScreenState _state = AuthScreenState.idle;

  AuthScreenState get state => _state;

  bool get isLoading => _state == AuthScreenState.loading;

  /// Красный текст ошибки.
  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  /// Зелёный информационный текст ("проверьте почту" и т.п.).
  String _infoMessage = '';

  String get infoMessage => _infoMessage;

  void clearMessages() {
    _errorMessage = '';
    _infoMessage = '';
    if (_state == AuthScreenState.error) _state = AuthScreenState.idle;
    notifyListeners();
  }

  void _startLoading() {
    _state = AuthScreenState.loading;
    _errorMessage = '';
    _infoMessage = '';
    notifyListeners();
  }

  void _fail(Object e) {
    _state = AuthScreenState.error;
    _errorMessage = authErrorMessage(e);
    notifyListeners();
  }

  /// true — вошли успешно, экран можно закрывать.
  Future<bool> signIn({required String password, required String email}) async {
    _startLoading();
    try {
      final user = await repository.signIn(password: password, email: email);
      _state = AuthScreenState.idle;
      notifyListeners();
      return user != null;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  /// true — пользователь сразу вошёл. false — ошибка ИЛИ нужно подтвердить
  /// почту (тогда [infoMessage] не пустой).
  Future<bool> signUp({
    required String password,
    required String email,
    String? fullName,
  }) async {
    _startLoading();
    try {
      final result = await repository.signUp(
        password: password,
        email: email,
        fullName: fullName,
      );
      _state = AuthScreenState.idle;
      if (result == SignUpResult.needsEmailConfirmation) {
        _infoMessage =
            'Account created! We sent a confirmation link to ${email.trim()}. '
            'Open it, then sign in here.';
      }
      notifyListeners();
      return result == SignUpResult.signedIn;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _startLoading();
    try {
      await repository.sendPasswordReset(email);
      _state = AuthScreenState.idle;
      _infoMessage =
          'If an account exists for ${email.trim()}, a password reset link '
          'has been sent.';
      notifyListeners();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }
}
