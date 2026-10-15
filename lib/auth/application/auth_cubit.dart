import 'package:flutter_bloc/flutter_bloc.dart';

class AuthUser {
  const AuthUser({required this.id, required this.email});
  final String id;
  final String email;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

abstract interface class AuthRepository {
  Future<AuthUser> signIn(String email, String password);
  Future<void> signOut();
}

// shortcut: sesión simulada sin verificar identidad, sustituir por backend al autenticar usuarios reales.
class DemoAuthRepository implements AuthRepository {
  @override
  Future<AuthUser> signIn(String email, String password) async =>
      AuthUser(id: 'demo-user', email: email);

  @override
  Future<void> signOut() async {}
}

class AuthState {
  const AuthState({this.user, this.busy = false, this.error});
  final AuthUser? user;
  final bool busy;
  final String? error;
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this.repository) : super(const AuthState());
  final AuthRepository repository;

  Future<bool> signIn(String email, String password) async {
    if (state.busy || state.user != null) return false;
    final cleanEmail = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(cleanEmail) ||
        password.isEmpty) {
      emit(const AuthState(
          error: 'Introduce un correo válido y una contraseña.'));
      return false;
    }
    emit(const AuthState(busy: true));
    try {
      final user = await repository.signIn(cleanEmail, password);
      if (isClosed) return false;
      emit(AuthState(user: user));
      return true;
    } on AuthException catch (error) {
      if (!isClosed) emit(AuthState(error: error.message));
    } catch (_) {
      if (!isClosed) {
        emit(const AuthState(
            error: 'No se pudo iniciar sesión. Inténtalo otra vez.'));
      }
    }
    return false;
  }

  Future<void> signOut() async {
    if (state.busy || state.user == null) return;
    final user = state.user;
    emit(AuthState(user: user, busy: true));
    try {
      await repository.signOut();
      if (!isClosed) emit(const AuthState());
    } catch (_) {
      if (!isClosed) {
        emit(AuthState(
            user: user, error: 'No se pudo cerrar la sesión. Reintenta.'));
      }
    }
  }
}
