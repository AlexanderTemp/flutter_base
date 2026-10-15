import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/main.dart';
import 'package:flutter_workspace/settings/presentation/settings_page.dart';
import 'package:flutter_workspace/workspace/presentation/workspace_widgets.dart';

void main() {
  Future<void> openApp(WidgetTester tester, {double width = 390}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(finder, 180,
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

  testWidgets('navegación inferior busca y crea sin perder tareas',
      (tester) async {
    await openApp(tester);
    expect(find.byType(WorkspaceBottomNavigation), findsOneWidget);
    await tapKey(tester, 'bottom-search');
    await tester.enterText(find.byType(TextField), 'estado');
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceTaskRow), findsOneWidget);
    await tapKey(tester, 'bottom-settings');
    expect(find.byType(SettingsPage), findsOneWidget);
    await tapKey(tester, 'bottom-create');
    await tester.enterText(find.byType(TextField).last, 'Segunda fase');
    await tapKey(tester, 'submit-task');
    expect(find.text('Segunda fase'), findsOneWidget);
    expect(find.byType(WorkspaceTaskRow), findsNWidgets(4));

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceBottomNavigation), findsNothing);
    await tapKey(tester, 'sidebar-settings');
    await tapKey(tester, 'sidebar-tasks');
    expect(find.text('Segunda fase'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('los ajustes cambian tema, filas, visibilidad y nombre',
      (tester) async {
    await openApp(tester);
    await tapKey(tester, 'bottom-settings');
    await tapKey(tester, 'settings-appearance');
    await tapKey(tester, 'theme-dark');
    expect(Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark);
    await tapKey(tester, 'compact-toggle');
    await tapKey(tester, 'completed-toggle');
    await tapKey(tester, 'bottom-tasks');
    expect(find.byType(WorkspaceTaskRow), findsNWidgets(2));
    expect(
        tester
            .widgetList<WorkspaceTaskRow>(find.byType(WorkspaceTaskRow))
            .every((row) => row.compact),
        isTrue);
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-completed');
    expect(find.byType(WorkspaceTaskRow), findsOneWidget);

    await tapKey(tester, 'bottom-settings');
    await tapKey(tester, 'settings-back');
    await tapKey(tester, 'settings-workspace');
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Guardar nombre'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un nombre de entre 1 y 40 caracteres'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Mi estudio  ');
    await tester.tap(find.text('Guardar nombre'));
    await tester.pumpAndSettle();
    expect(find.text('Mi estudio / Ajustes'), findsOneWidget);
    await tapKey(tester, 'settings-back');
    await tapKey(tester, 'settings-about');
    await tester.ensureVisible(find.text('Restablecer preferencias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restablecer preferencias'));
    await tester.pumpAndSettle();
    expect(find.text('Mi espacio / Ajustes'), findsOneWidget);
    await tapKey(tester, 'bottom-tasks');
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'nav-all');
    expect(find.byType(WorkspaceTaskRow), findsNWidgets(3));
    expect(
        tester
            .widgetList<WorkspaceTaskRow>(find.byType(WorkspaceTaskRow))
            .every((row) => !row.compact),
        isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ajustes accesibles con teclado y ampliación del sistema',
      (tester) async {
    await openApp(tester, width: 320);
    await tapKey(tester, 'bottom-settings');
    await tapKey(tester, 'settings-appearance');
    await tapKey(tester, 'text-scale-1.3');
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    final media = MediaQuery.of(tester.element(find.byType(Scaffold)));
    expect(media.textScaler.scale(10), closeTo(23.4, 0.01));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compact-toggle')),
      180,
      scrollable: find
          .descendant(
              of: find.byType(SettingsPage), matching: find.byType(Scrollable))
          .last,
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel('Filas compactas'), findsOneWidget);
    final focus = find.descendant(
        of: find.byKey(const ValueKey('compact-toggle')),
        matching: find.byType(Focus));
    tester.widget<Focus>(focus.first).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tapKey(tester, 'bottom-tasks');
    expect(
        tester
            .widgetList<WorkspaceTaskRow>(find.byType(WorkspaceTaskRow))
            .every((row) => row.compact),
        isTrue);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}
