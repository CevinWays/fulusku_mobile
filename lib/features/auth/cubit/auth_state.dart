import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial — belum cek session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Sedang proses login/register/cek session.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User terlogin.
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.id, user.email];
}

/// Belum login atau session expired.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error dengan pesan untuk ditampilkan ke user.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Setelah register sukses tapi butuh email confirmation.
class AuthAwaitingConfirmation extends AuthState {
  final String email;
  const AuthAwaitingConfirmation(this.email);

  @override
  List<Object?> get props => [email];
}
