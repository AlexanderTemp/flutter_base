import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/auth/application/auth_cubit.dart';

class ControlledAuthRepository implements AuthRepository {
  final response = Completer<AuthUser>();
  int calls = 0;
  bool failSignOut = false;

  @override
  Future<AuthUser> signIn(String email, String password) {
    calls++;
    return response.future;
  }

  @override
  Future<void> signOut() async {
    if (failSignOut) throw Exception('unavailable');
  }
}

void main() {
  test('valida, bloquea duplicados y conserva la sesión si falla salir',
      () async {
    final repository = ControlledAuthRepository();
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);
    expect(await cubit.signIn('invalido', 'demo'), isFalse);
    expect(await cubit.signIn('demo@ejemplo.com', ''), isFalse);
    expect(repository.calls, 0);
    final pending = cubit.signIn('  demo@ejemplo.com  ', 'demo');
    expect(cubit.state.busy, isTrue);
    expect(await cubit.signIn('demo@ejemplo.com', 'demo'), isFalse);
    expect(repository.calls, 1);
    repository.response
        .complete(const AuthUser(id: '1', email: 'demo@ejemplo.com'));
    expect(await pending, isTrue);
    expect(cubit.state.user!.id, '1');
    expect(cubit.state.busy, isFalse);
    repository.failSignOut = true;
    await cubit.signOut();
    expect(cubit.state.user!.id, '1');
    expect(cubit.state.error, isNotNull);
    repository.failSignOut = false;
    await cubit.signOut();
    expect(cubit.state.user, isNull);
  });

  test('expone el error del servicio y permite reintentar', () async {
    final repository = ControlledAuthRepository();
    final cubit = AuthCubit(repository);
    addTearDown(cubit.close);
    final pending = cubit.signIn('demo@ejemplo.com', 'demo');
    repository.response
        .completeError(const AuthException('Credenciales rechazadas'));
    expect(await pending, isFalse);
    expect(cubit.state.error, 'Credenciales rechazadas');
    expect(cubit.state.busy, isFalse);
    expect(cubit.state.user, isNull);
    expect(await cubit.signIn('demo@ejemplo.com', 'demo'), isFalse);
    expect(repository.calls, 2);
  });

  test('una respuesta tardía no emite sobre un Cubit cerrado', () async {
    final repository = ControlledAuthRepository();
    final cubit = AuthCubit(repository);
    final pending = cubit.signIn('demo@ejemplo.com', 'demo');
    await cubit.close();
    repository.response
        .complete(const AuthUser(id: '1', email: 'demo@ejemplo.com'));
    expect(await pending, isFalse);
  });
}
