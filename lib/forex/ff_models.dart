// Modelos de datos de Forex Factory. Dart puro (sin Flutter) para poder
// probar la lógica con `dart run` sin compilar la app.

// Un evento del calendario económico.
class FfEvent {
  FfEvent({
    required this.id,
    required this.name,
    required this.currency,
    required this.impact,
    required this.time,
    required this.actual,
    required this.forecast,
    required this.previous,
    required this.betterWorse,
  });

  final int id;
  final String name;
  final String currency;

  /// 'high' (roja), 'medium', 'low', 'holiday'.
  final String impact;

  /// Momento del evento (hora local; derivado del timestamp Unix).
  final DateTime time;

  final String actual;
  final String forecast;
  final String previous;

  /// Veredicto propio de FF: 1 = mejor de lo esperado, 2 = peor, 0 = neutral.
  final int betterWorse;

  bool get isHigh => impact == 'high';

  /// El dato ya salió cuando 'actual' deja de estar vacío.
  bool get released => actual.trim().isNotEmpty;

  /// Desde el feed oficial de FairEconomy (ff_calendar_thisweek.json).
  /// Ese feed trae la programación pero NO el valor 'actual'.
  factory FfEvent.fromFeed(Map<String, dynamic> j) {
    final impactRaw = (j['impact'] ?? '').toString().toLowerCase();
    return FfEvent(
      // El feed no da id; usamos un hash estable de título+fecha.
      id: ('${j['title']}|${j['date']}').hashCode,
      name: (j['title'] ?? '').toString(),
      currency: (j['country'] ?? '').toString(),
      impact: impactRaw, // 'high' | 'medium' | 'low' | 'holiday'
      time: DateTime.parse((j['date']).toString()).toLocal(),
      actual: '', // el feed nunca trae 'actual'
      forecast: (j['forecast'] ?? '').toString(),
      previous: (j['previous'] ?? '').toString(),
      betterWorse: 0,
    );
  }

  factory FfEvent.fromJson(Map<String, dynamic> j) => FfEvent(
        id: (j['id'] as num).toInt(),
        name: (j['name'] ?? '').toString(),
        currency: (j['currency'] ?? '').toString(),
        impact: (j['impactName'] ?? '').toString(),
        time: DateTime.fromMillisecondsSinceEpoch(
            ((j['dateline'] as num).toInt()) * 1000),
        actual: (j['actual'] ?? '').toString(),
        forecast: (j['forecast'] ?? '').toString(),
        previous: (j['previous'] ?? '').toString(),
        betterWorse: (j['actualBetterWorse'] as num?)?.toInt() ?? 0,
      );
}

/// Un release histórico (para la tendencia).
class FfHistoryPoint {
  FfHistoryPoint(
      {required this.date,
      required this.actual,
      required this.forecast,
      required this.previous,
      required this.betterWorse});

  final String date;
  final String actual;
  final String forecast;
  final String previous;
  final int betterWorse;

  factory FfHistoryPoint.fromJson(Map<String, dynamic> j) => FfHistoryPoint(
        date: (j['date'] ?? '').toString(),
        actual: (j['actual'] ?? '').toString(),
        forecast: (j['forecast'] ?? '').toString(),
        previous: (j['previous'] ?? '').toString(),
        betterWorse: (j['actualBetterWorse'] as num?)?.toInt() ?? 0,
      );
}

/// Detalle de un evento: especificaciones (regla, qué mide…) e histórico.
class FfDetail {
  FfDetail({required this.specs, required this.history});

  /// Claves: 'Usual Effect', 'Why Traders Care', 'Measures', 'Source'…
  final Map<String, String> specs;
  final List<FfHistoryPoint> history;

  String get usualEffect => specs['Usual Effect'] ?? '';
  String get why => specs['Why Traders Care'] ?? specs['Why Traders<br>Care'] ?? '';
  String get measures => specs['Measures'] ?? '';
}
