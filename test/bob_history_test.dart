import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/bob/bob_client.dart';
import 'package:flutter_workspace/forex/bob/bob_controller.dart';
import 'package:flutter_workspace/forex/bob/bob_view.dart';

const _html = '''
<div class="tco-public-value">Bs 11,68/\$us</div>
<span>VIGENCIA: VIERNES 16 DE OCTUBRE DE 2026</span>
<table class="tco-public-table"><tr><td>BANCO</td><td>90,00</td></tr></table>
<table class="tco-daily-table"><thead><tr><th>Fecha</th><th>Valor</th></tr></thead><tbody>
<tr><td>jueves 15 de octubre de 2026</td><td>11,68</td></tr>
<tr><td>miércoles 14 de octubre de 2026</td><td>11,70</td></tr>
<tr><td>viernes 16 de octubre de 2026</td><td>11,68</td></tr>
<tr><td>viernes 16 de octubre de 2026</td><td>11,68</td></tr>
</tbody></table>
''';

void main() {
  test(
    'BCB parsing keeps the current quote and daily records in exact cents',
    () {
      final rate = BobClient.parse(_html);
      expect(rate.value, '11,68');
      expect(rate.date, DateTime(2026, 10, 16));
      expect(rate.history.map((point) => point.cents), [1168, 1168, 1170]);
      expect(rate.history.first.date, DateTime(2026, 10, 16));
      expect(rate.history[1].cents - rate.history[2].cents, -2);
      expect(formatBobCents(-2), '−0,02');
      expect(BobRate.fromJson(rate.toJson()).history.last.cents, 1170);
    },
  );

  test('invalid dates and amounts are rejected instead of fabricated', () {
    expect(
      () => BobClient.parse(_html.replaceAll('14 de octubre', '32 de octubre')),
      throwsFormatException,
    );
    expect(
      () => BobClient.parse(_html.replaceAll('11,70', 'sin dato')),
      throwsFormatException,
    );
    expect(
      () => BobClient.parse('<html>Servicio no disponible</html>'),
      throwsFormatException,
    );
  });

  testWidgets(
    'BOB panel changes record limits and always shows the current quote',
    (tester) async {
      final controller = BobController()
        ..rate = BobRate(
          value: '11,68',
          vigencia: '16 de octubre de 2026',
          date: DateTime(2026, 10, 16),
          history: List.generate(
            60,
            (index) => BobPoint(
              date: DateTime(2026, 10, 16).subtract(Duration(days: index)),
              cents: 1168 - index,
            ),
          ),
        );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: AppFlowyTheme(
            data: AppFlowyDefaultTheme().light(),
            child: Scaffold(body: BobView(controller: controller)),
          ),
        ),
      );
      expect(find.text('Vigente 16/10/2026'), findsOneWidget);
      expect(find.textContaining('30 registros ·'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, '7 registros'));
      await tester.pumpAndSettle();
      expect(find.textContaining('7 registros ·'), findsOneWidget);
      expect(find.text('Variación del rango · +0,06 Bs'), findsOneWidget);
      final fifty = find.widgetWithText(ChoiceChip, '50 registros');
      await tester.ensureVisible(fifty);
      await tester.tap(fifty);
      await tester.pumpAndSettle();
      expect(find.textContaining('50 registros ·'), findsOneWidget);
    },
  );
}
