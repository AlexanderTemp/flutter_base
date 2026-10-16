import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/design_system/workspace_controls.dart';
import 'package:flutter_workspace/main.dart';
import 'package:flutter_workspace/settings/presentation/settings_page.dart';
import 'package:flutter_workspace/workspace/presentation/workspace_widgets.dart';

void main() {
  test('los colores semánticos mantienen contraste claro y oscuro', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final theme in [
      AppFlowyDefaultTheme().light(),
      AppFlowyDefaultTheme().dark(),
    ]) {
      for (final pair in [
        (theme.textColorScheme.primary, theme.fillColorScheme.warningLight),
        (theme.textColorScheme.info, theme.fillColorScheme.infoLight),
        (theme.textColorScheme.warning, theme.fillColorScheme.warningLight),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
      for (final surface in [
        theme.surfaceColorScheme.primary,
        theme.surfaceColorScheme.layer02,
      ]) {
        expect(contrast(theme.textColorScheme.success, surface),
            greaterThanOrEqualTo(4.5));
        expect(contrast(theme.textColorScheme.error, surface),
            greaterThanOrEqualTo(4.5));
      }
    }
  });

  testWidgets('buscar ignora tildes y limpiar conserva las tareas',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    await tester.ensureVisible(find.byKey(const ValueKey('new-task')));
    await tester.tap(find.byKey(const ValueKey('new-task')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'Revisión de aplicación');
    await tester.tap(find.byKey(const ValueKey('submit-task')));
    await tester.pumpAndSettle();
    final field = find.descendant(
        of: find.byKey(const ValueKey('search-tasks')),
        matching: find.byType(TextField));
    await tester.enterText(field, 'REVISION');
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceTaskRow), findsOneWidget);
    expect(find.text('Revisión de aplicación'), findsOneWidget);
    await tester.enterText(field, 'inexistente');
    await tester.pumpAndSettle();
    expect(find.text('No hay tareas que coincidan.'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceTaskRow), findsNWidgets(4));
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    await tester.tap(find.byKey(const ValueKey('sidebar-settings')));
    await tester.pumpAndSettle();
    expect(
        TickerMode.of(tester.element(
            find.byKey(const ValueKey('search-tasks'), skipOffstage: false))),
        isFalse);
    expect(TickerMode.of(tester.element(find.byType(SettingsPage))), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('los interruptores respetan reducción de movimiento',
      (tester) async {
    for (final media in [
      const MediaQueryData(disableAnimations: true),
      const MediaQueryData(accessibleNavigation: true),
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: media,
          child: AppFlowyTheme(
            data: AppFlowyDefaultTheme().light(),
            child: Scaffold(
                body: WorkspaceToggle(
              label: 'Opción',
              description: 'Descripción',
              value: false,
              onChanged: (_) {},
            )),
          ),
        ),
      ));
      final toggle = find.descendant(
          of: find.byType(WorkspaceToggle),
          matching: find.byType(AnimatedContainer));
      expect(tester.widget<AnimatedContainer>(toggle).duration, Duration.zero);
    }
  });
}
