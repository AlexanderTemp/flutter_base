import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/guide/guide_view.dart';

Widget _app({bool dark = false}) => MaterialApp(
  theme: dark ? ThemeData.dark() : ThemeData.light(),
  home: AppFlowyTheme(
    data: dark ? AppFlowyDefaultTheme().dark() : AppFlowyDefaultTheme().light(),
    child: const Scaffold(body: GuideView()),
  ),
);

void main() {
  testWidgets('guide reveals explanations on demand without a feed', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.text('Real, previsión y previo'), findsOneWidget);
    expect(find.textContaining('inflación previa 3,0 %'), findsNothing);
    await tester.tap(find.text('Real, previsión y previo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('inflación previa 3,0 %'), findsOneWidget);
    await tester.pumpWidget(_app(dark: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('inflación previa 3,0 %'), findsOneWidget);
    await tester.tap(find.text('Real, previsión y previo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('inflación previa 3,0 %'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'search matches abbreviations and body text, ignoring case and accents',
    (tester) async {
      await tester.pumpWidget(_app());
      final search = find.byType(TextField);
      await tester.enterText(search, '  cPi  ');
      await tester.pumpAndSettle();
      expect(find.text('Inflación: CPI / IPC y PPI'), findsOneWidget);
      expect(
        find.textContaining('precios que pagan los consumidores'),
        findsOneWidget,
      );
      expect(find.text('Empleo, PIB y PMI'), findsNothing);

      await tester.enterText(search, 'INFLACION CPI');
      await tester.pumpAndSettle();
      expect(find.text('Inflación: CPI / IPC y PPI'), findsOneWidget);
      expect(find.text('1 tema encontrado'), findsOneWidget);

      await tester.enterText(search, 'jobless');
      await tester.pumpAndSettle();
      expect(find.text('Empleo, PIB y PMI'), findsOneWidget);
      expect(find.textContaining('solicitudes de subsidio'), findsOneWidget);

      await tester.enterText(search, 'zzzzzz');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No hay temas con esa búsqueda'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(find.text('Por dónde empezar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
