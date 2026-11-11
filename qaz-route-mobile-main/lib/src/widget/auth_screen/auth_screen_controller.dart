import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';

enum AuthScreenState { loading, idle, error }

class AuthScreenController extends ChangeNotifier {
  AuthScreenController({required this.repository});

  final AuthRepository repository;

  AuthScreenState _state = AuthScreenState.idle;

  AuthScreenState get state => _state;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  Future<bool> signIn({required String password, required String email}) async {
    try {
      _state = AuthScreenState.loading;
      _errorMessage = '';
      notifyListeners();

      final user = await repository.signIn(password: password, email: email);

      return user != null;
    } catch (e) {
      _state = AuthScreenState.error;
      _errorMessage = 'Failed to sign in: ${e.toString()}';
      notifyListeners();
    }

    return false;
  }

  Future<bool> signUp({required String password, required String email}) async {
    try {
      _state = AuthScreenState.loading;
      _errorMessage = '';
      notifyListeners();

      final user = await repository.signUp(password: password, email: email);

      return user != null;
    } catch (e) {
      _state = AuthScreenState.error;
      _errorMessage = 'Failed to sign up: ${e.toString()}';
      notifyListeners();
    }

    return false;
  }
}
