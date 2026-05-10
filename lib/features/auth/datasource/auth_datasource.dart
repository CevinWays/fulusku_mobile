import 'package:supabase_flutter/supabase_flutter.dart';

/// Datasource Supabase Auth.
/// Wrap pemanggilan API supaya cubit tidak depend langsung pada SDK.
class AuthDatasource {
  final SupabaseClient _client;

  AuthDatasource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  User? getCurrentUser() => _client.auth.currentUser;

  Session? getCurrentSession() => _client.auth.currentSession;

  /// Stream untuk dengar perubahan auth state (login/logout/refresh).
  Stream<AuthState> onAuthStateChange() => _client.auth.onAuthStateChange;

  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }
}
