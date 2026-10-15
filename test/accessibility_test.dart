import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/main.dart';
import 'package:flutter_workspace/settings/presentation/settings_page.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'áreas táctiles, etiquetas y contraste en tema ${dark ? 'oscuro' : 'claro'}',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const WorkspaceApp());
        if (dark) await tester.tap(find.byTooltip('Cambiar tema'));
        await tester.pumpAndSettle();
        Future<void> check() async {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }

        await check();
        await tester.tap(find.byKey(const ValueKey('bottom-settings')));
        await tester.pumpAndSettle();
        await check();
        await tester
            .ensureVisible(find.byKey(const ValueKey('settings-appearance')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('settings-appearance')));
        await tester.pumpAndSettle();
        await check();
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('completed-toggle')), 180,
            scrollable: find
                .descendant(
                    of: find.byType(SettingsPage),
                    matching: find.byType(Scrollable))
                .last);
        await tester.pumpAndSettle();
        await check();
        await tester.tap(find.byKey(const ValueKey('settings-back')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('account-entry')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('account-entry')));
        await tester.pumpAndSettle();
        await check();
      } finally {
        semantics.dispose();
      }
    });
  }
}
