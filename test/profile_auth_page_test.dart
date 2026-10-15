import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/auth/presentation/sign_in_page.dart';
import 'package:flutter_workspace/auth/application/auth_cubit.dart';
import 'package:flutter_workspace/main.dart';
import 'package:flutter_workspace/settings/presentation/profile_editor.dart';
import 'package:flutter_workspace/settings/presentation/settings_page.dart';
import 'package:flutter_workspace/settings/application/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _RetryAuthRepository implements AuthRepository {
  final first = Completer<AuthUser>();
  int calls = 0;

  @override
  Future<AuthUser> signIn(String email, String password) {
    calls++;
    return calls == 1
        ? first.future
        : Future.value(AuthUser(id: 'demo', email: email));
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
          finder, key == 'settings-profile' ? -180 : 180,
          scrollable: find
              .descendant(
                  of: find.byType(SettingsPage),
                  matching: find.byType(Scrollable))
              .last);
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'el borrador de perfil conserva nombre, descripción y color al redimensionar',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    await tap(tester, 'sidebar-settings');
    final fields = find.descendant(
        of: find.byType(ProfileEditor), matching: find.byType(TextField));
    await tester.enterText(fields.first, 'Borrador pendiente');
    await tester.enterText(fields.last, 'Descripción pendiente');
    await tester.tap(find.text('Violeta'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(900, 900);
    await tester.pumpAndSettle();
    await tap(tester, 'settings-profile');
    expect(tester.widget<TextField>(fields.first).controller!.text,
        'Borrador pendiente');
    expect(tester.widget<TextField>(fields.last).controller!.text,
        'Descripción pendiente');
    expect(tester.widget<ProfileEditor>(find.byType(ProfileEditor)).color, 3);
    final cubit =
        tester.element(find.byType(ProfileEditor)).read<SettingsCubit>();
    expect(cubit.state.profileName, 'Mi perfil');
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    expect(cubit.state.profileName, 'Borrador pendiente');
    expect(cubit.state.profileBio, 'Descripción pendiente');
    expect(cubit.state.avatarColor, 3);
  });

  testWidgets(
      'el acceso reabierto se cierra al completarse una solicitud anterior',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _RetryAuthRepository();
    await tester.pumpWidget(WorkspaceApp(authRepository: repository));
    await tap(tester, 'bottom-settings');
    await tap(tester, 'account-entry');
    await tester.enterText(find.byType(TextField).first, 'demo@ejemplo.com');
    await tester.enterText(find.byType(TextField).last, 'ficticia');
    await tap(tester, 'sign-in-submit');
    await tester.tap(find.byTooltip('Cerrar inicio de sesión'));
    await tester.pumpAndSettle();
    await tap(tester, 'account-entry');
    repository.first
        .complete(const AuthUser(id: 'demo', email: 'demo@ejemplo.com'));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsNothing);
    expect(find.text('Sesión de demostración'), findsOneWidget);
    expect(repository.calls, 1);
  });
  testWidgets('acceso muestra carga, error del servicio y permite reintentar',
      (tester) async {
    final repository = _RetryAuthRepository();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(WorkspaceApp(authRepository: repository));
    await tester.tap(find.byKey(const ValueKey('bottom-settings')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('account-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'demo@ejemplo.com');
    await tester.enterText(find.byType(TextField).last, 'ficticia');
    final submit = find.byKey(const ValueKey('sign-in-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Conectando…'), findsOneWidget);
    repository.first
        .completeError(const AuthException('Acceso rechazado por el servicio'));
    await tester.pumpAndSettle();
    expect(find.text('Acceso rechazado por el servicio'), findsOneWidget);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.byType(SignInPage), findsNothing);
    expect(find.text('Sesión de demostración'), findsOneWidget);
  });
  testWidgets('perfil editable, volver, acceso demo y cierre sin borrar tareas',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    await tap(tester, 'bottom-settings');
    await tap(tester, 'settings-profile');
    final fields = find.descendant(
        of: find.byType(ProfileEditor), matching: find.byType(TextField));
    await tester.enterText(fields.first, '   ');
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un nombre de entre 1 y 40 caracteres'),
        findsOneWidget);
    await tester.enterText(fields.first, 'Alexander');
    await tester.enterText(fields.last, 'Aprendiendo Flutter');
    await tester.tap(find.text('Violeta'));
    await tester.tap(find.text('Guardar perfil'));
    await tester.pumpAndSettle();
    await tap(tester, 'settings-back');
    expect(find.text('Alexander'), findsOneWidget);
    await tap(tester, 'account-entry');
    expect(find.byType(SignInPage), findsOneWidget);
    await tap(tester, 'sign-in-submit');
    expect(find.text('Introduce un correo válido y una contraseña.'),
        findsOneWidget);
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('sign-in-email')),
            matching: find.byType(TextField)),
        'demo@ejemplo.com');
    await tester.enterText(
        find.descendant(
            of: find.byKey(const ValueKey('sign-in-password')),
            matching: find.byType(TextField)),
        'ficticia');
    await tap(tester, 'sign-in-submit');
    expect(find.byType(SignInPage), findsNothing);
    expect(find.text('Sesión de demostración'), findsOneWidget);
    await tap(tester, 'settings-profile');
    await tap(tester, 'profile-session');
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Cerrar sesión demo'), findsNothing);
    await tap(tester, 'bottom-tasks');
    expect(find.text('Explorar el sistema de diseño'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'cerrar acceso conserva el invitado y volver del sistema abre el índice',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    await tap(tester, 'bottom-settings');
    await tap(tester, 'account-entry');
    await tester.tap(find.byTooltip('Cerrar inicio de sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    await tap(tester, 'settings-profile');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-entry')), findsOneWidget);
    expect(find.byType(ProfileEditor), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
