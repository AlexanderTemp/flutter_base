import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/app_info.dart';
import 'package:flutter_workspace/main.dart';
import 'package:flutter_workspace/workspace/presentation/workspace_page.dart';

void main() {
  testWidgets(
      'las etiquetas quedan centradas con altura extra y texto ampliado',
      (tester) async {
    for (final scale in [1.0, 1.8]) {
      for (final size in AFButtonSize.values) {
        final buttons = [
          AFFilledTextButton.primary(text: 'Guardar', onTap: () {}, size: size),
          AFOutlinedTextButton.normal(
              text: 'Cancelar', onTap: () {}, size: size),
          AFGhostTextButton.primary(text: 'Opciones', onTap: () {}, size: size),
        ];
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: AppFlowyTheme(
              data: AppFlowyDefaultTheme().light(),
              child: Scaffold(
                  body: Center(
                      child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < buttons.length; i++)
                    SizedBox(
                      key: ValueKey('button-$i'),
                      width: 240,
                      height: 80,
                      child: buttons[i],
                    ),
                ],
              ))),
            ),
          ),
        ));
        for (var i = 0; i < buttons.length; i++) {
          final button = find.byKey(ValueKey('button-$i'));
          final label =
              find.descendant(of: button, matching: find.byType(Text));
          expect(tester.getCenter(label).dy,
              closeTo(tester.getCenter(button).dy, .01),
              reason: 'Variante $i, tamaño $size, escala $scale');
        }
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets(
      'la versión Android refleja el APK y sus overrides de compilación',
      (tester) async {
    const channel = MethodChannel('app/info');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (call) async => call.method == 'version' ? '2.3.4+42' : null);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    expect(await AppInfo.loadVersion(), '2.3.4+42');
  }, variant: TargetPlatformVariant({TargetPlatform.android}));

  testWidgets(
      'el área completa del botón responde y deshabilitar retira el foco',
      (tester) async {
    var taps = 0;
    Future<void> showButton({bool disabled = false, bool callback = true}) =>
        tester.pumpWidget(MaterialApp(
          home: AppFlowyTheme(
            data: AppFlowyDefaultTheme().light(),
            child: Scaffold(
              body: Center(
                child: AFBaseButton(
                  key: const ValueKey('button'),
                  onTap: callback ? () => taps++ : null,
                  disabled: disabled,
                  padding: const EdgeInsets.all(12),
                  borderRadius: 8,
                  builder: (_, __, ___) => const Text('OK'),
                ),
              ),
            ),
          ),
        ));

    await showButton();
    final button = find.byKey(const ValueKey('button'));
    await tester.tapAt(tester.getBottomRight(button) - const Offset(2, 2));
    expect(taps, 1);
    final focusFinder =
        find.descendant(of: button, matching: find.byType(Focus));
    tester.widget<Focus>(focusFinder).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 2);

    for (final disabled in [true, false]) {
      await showButton(disabled: disabled, callback: disabled);
      await tester.pump();
      final focus = tester.widget<Focus>(focusFinder).focusNode!;
      expect(focus.canRequestFocus, isFalse);
      expect(focus.hasFocus, isFalse);
      await tester.tap(button);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 2);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('cabecera, controles y barras del sistema comparten el tema',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    await tester.pumpAndSettle();

    Brightness checkTheme() {
      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      final tokens = AppFlowyTheme.of(context);
      expect(theme.colorScheme.primary, tokens.fillColorScheme.themeThick);
      expect(theme.colorScheme.onSurface, tokens.textColorScheme.primary);
      final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(find
          .ancestor(
              of: find.byType(WorkspacePage),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>))
          .first);
      final icons = theme.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark;
      expect(overlay.value.statusBarIconBrightness, icons);
      expect(overlay.value.systemNavigationBarIconBrightness, icons);
      expect(overlay.value.systemNavigationBarColor,
          theme.scaffoldBackgroundColor);
      return theme.brightness;
    }

    final initial = checkTheme();
    await tester.tap(find.byTooltip('Cambiar tema'));
    await tester.pumpAndSettle();
    expect(checkTheme(), isNot(initial));
    await tester.tap(find.byKey(const ValueKey('header-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-profile')), findsOneWidget);
    await tester.tap(find.byTooltip('Cambiar tema'));
    await tester.pumpAndSettle();
    expect(checkTheme(), initial);
    expect(tester.takeException(), isNull);
  });
}
