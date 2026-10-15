// Tests del motor de reglas (alcista/bajista), sin red ni IA.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/forex/ff_models.dart';
import 'package:flutter_workspace/forex/ff_analyzer.dart';

FfEvent _ev({
  required String currency,
  required String actual,
  required String forecast,
  required String previous,
}) =>
    FfEvent(
      id: 1,
      name: 'Test',
      currency: currency,
      impact: 'high',
      time: DateTime.now(),
      actual: actual,
      forecast: forecast,
      previous: previous,
      betterWorse: 0,
    );

FfDetail _detail(String usualEffect) =>
    FfDetail(specs: {'Usual Effect': usualEffect}, history: []);

void main() {
  test('actual > forecast con "greater is good" => alcista', () {
    final a = FfAnalyzer.analyze(
      _ev(currency: 'USD', actual: '0.3%', forecast: '0.2%', previous: '0.3%'),
      _detail("'Actual' greater than 'Forecast' is good for currency;"),
    );
    expect(a.bias, Bias.alcista);
  });

  test('regla inversa: paro al alza con "less is good" => bajista', () {
    final a = FfAnalyzer.analyze(
      _ev(currency: 'AUD', actual: '4.7%', forecast: '4.6%', previous: '4.6%'),
      _detail("'Actual' less than 'Forecast' is good for currency;"),
    );
    expect(a.bias, Bias.bajista);
  });

  test('actual == forecast => neutral', () {
    final a = FfAnalyzer.analyze(
      _ev(currency: 'USD', actual: '0.6%', forecast: '0.6%', previous: '0.4%'),
      _detail("'Actual' greater than 'Forecast' is good for currency;"),
    );
    expect(a.bias, Bias.neutral);
  });

  test('toNum interpreta sufijos K/M y negativos', () {
    expect(FfAnalyzer.toNum('-39.3K'), -39300);
    expect(FfAnalyzer.toNum('1.2M'), 1200000);
    expect(FfAnalyzer.toNum('<0.1%'), 0.1);
    expect(FfAnalyzer.toNum(''), isNull);
  });
}
