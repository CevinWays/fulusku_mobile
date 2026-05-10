import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../datasource/auth_datasource.dart';
import 'auth_state.dart';

/// AuthCubit — manage authentication state global.
///
/// Subscribe ke [AuthDatasource.onAuthStateChange] saat [checkSession]
/// dipanggil supaya state otomatis update saat session berubah dari
/// background (token refresh, sign out dari device lain, dll).
class AuthCubit extends Cubit<AuthState> {
  final AuthDatasource _datasource;
  StreamSubscription<sb.AuthState>? _authSubscription;

  AuthCubit(this._datasource) : super(const AuthInitial());

  /// Cek session saat app start. Subscribe ke stream untuk reactivity.
  void checkSession() {
    final user = _datasource.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }

    // Subscribe sekali — auto-update state pada perubahan auth.
    _authSubscription ??= _datasource.onAuthStateChange().listen((data) {
      final session = data.session;
      switch (data.event) {
        case sb.AuthChangeEvent.signedIn:
        case sb.AuthChangeEvent.tokenRefreshed:
        case sb.AuthChangeEvent.userUpdated:
          if (session != null) emit(AuthAuthenticated(session.user));
          break;
        case sb.AuthChangeEvent.signedOut:
          emit(const AuthUnauthenticated());
          break;
        default:
          break;
      }
    });
  }

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final response = await _datasource.signIn(email: email, password: password);
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(const AuthError('Login gagal. Periksa email & password.'));
      }
    } on sb.AuthException catch (e) {
      emit(AuthError(_friendlyAuthError(e)));
    } catch (e) {
      emit(AuthError('Terjadi kesalahan: ${e.toString()}'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final response = await _datasource.signUp(
        name: name,
        email: email,
        password: password,
      );

      if (response.user != null && response.session != null) {
        // Auto-login (email confirmation off di Dashboard).
        emit(AuthAuthenticated(response.user!));
      } else if (response.user != null) {
        // Email confirmation aktif — user belum bisa login.
        emit(AuthAwaitingConfirmation(email));
      } else {
        emit(const AuthError('Registrasi gagal. Coba lagi.'));
      }
    } on sb.AuthException catch (e) {
      emit(AuthError(_friendlyAuthError(e)));
    } catch (e) {
      emit(AuthError('Terjadi kesalahan: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    try {
      await _datasource.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Gagal keluar: ${e.toString()}'));
    }
  }

  /// Reset state error ke unauthenticated/authenticated existing
  /// (misal user dismiss snackbar lalu coba lagi).
  void clearError() {
    final user = _datasource.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

/// Mapping pesan error Supabase → bahasa Indonesia ramah.
String _friendlyAuthError(sb.AuthException e) {
  final msg = e.message.toLowerCase();
  if (msg.contains('invalid login credentials')) {
    return 'Email atau password salah.';
  }
  if (msg.contains('email not confirmed')) {
    return 'Email belum diverifikasi. Cek inbox kamu.';
  }
  if (msg.contains('user already registered')) {
    return 'Email sudah terdaftar. Silakan masuk.';
  }
  if (msg.contains('password should be at least')) {
    return 'Password minimal 8 karakter.';
  }
  if (msg.contains('rate limit')) {
    return 'Terlalu banyak percobaan. Tunggu beberapa menit.';
  }
  return e.message;
}
