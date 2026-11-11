import 'package:flutter/foundation.dart';
import 'package:qaz_route_mobile/src/repository/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ProfileScreenState { loading, idle, error }

class ProfileScreenController extends ChangeNotifier {
  ProfileScreenController({required this.repository});

  final AuthRepository repository;

  ProfileScreenState _state = ProfileScreenState.idle;

  ProfileScreenState get state => _state;

  User? _user;

  User? get user => _user;

  String _errorMessage = '';

  String get errorMessage => _errorMessage;

  Future<void> getUser() async {
    try {
      _state = ProfileScreenState.loading;
      notifyListeners();

      final user = await repository.getUser();
      _user = user;

      _state = ProfileScreenState.idle;
    } catch (e) {
      _state = ProfileScreenState.error;
      _errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    try {
      await repository.signOut();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    await getUser();
  }
}
