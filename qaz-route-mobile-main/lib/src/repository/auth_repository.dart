import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository _instance = AuthRepository._();

  factory AuthRepository() => _instance;

  final supabase = Supabase.instance.client;

  Future<User?> signIn({
    required String password,
    required String email,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      password: password,
      email: email,
    );

    return response.user;
  }

  Future<User?> signUp({
    required String password,
    required String email,
  }) async {
    final response = await supabase.auth.signUp(
      password: password,
      email: email,
    );

    return response.user;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<User?> getUser() async {
    return supabase.auth.currentUser;
  }

  bool isAuthenticated() {
    return !(supabase.auth.currentSession?.isExpired ?? true);
  }
}
