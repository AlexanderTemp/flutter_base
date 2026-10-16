// TCO publicado por el BCB: última cotización y serie diaria en una sola consulta.
import 'package:http/http.dart' as http;

String formatBobCents(int cents) {
  final value = cents.abs();
  return '${cents < 0 ? '−' : ''}${value ~/ 100},${(value % 100).toString().padLeft(2, '0')}';
}

class BobPoint {
  const BobPoint({required this.date, required this.cents});
  final DateTime date;
  final int cents;

  String get value => formatBobCents(cents);
  Map<String, Object> toJson() => {
    'date': date.toIso8601String(),
    'cents': cents,
  };

  factory BobPoint.fromJson(Map<String, dynamic> json) {
    final cents = json['cents'] as int;
    if (cents <= 0) throw const FormatException('Cotización no válida');
    return BobPoint(date: DateTime.parse(json['date'] as String), cents: cents);
  }
}

class BobRate {
  BobRate({
    required this.value,
    required this.vigencia,
    this.date,
    this.history = const [],
  });
  final String value;
  final String vigencia;
  final DateTime? date;
  final List<BobPoint> history;

  Map<String, Object?> toJson() => {
    'value': value,
    'vigencia': vigencia,
    'date': date?.toIso8601String(),
    'history': [for (final point in history) point.toJson()],
  };

  factory BobRate.fromJson(Map<String, dynamic> json) {
    BobClient._cents(json['value'] as String);
    final history =
        (json['history'] as List)
            .map((point) => BobPoint.fromJson(point as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return BobRate(
      value: json['value'] as String,
      vigencia: json['vigencia'] as String,
      date: json['date'] == null
          ? null
          : DateTime.parse(json['date'] as String),
      history: history,
    );
  }
}

class BobClient {
  BobClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;
  String? warning;
  DateTime? get lastFetchedAt => _fetchedAt;

  static const _url =
      'https://www.bcb.gob.bo/bcb_tco_publico_ultima_cotizacion.php';

  static BobRate? _last; // sirve lo último si falla (cambia 1 vez/día)
  static DateTime? _fetchedAt;

  Future<BobRate?> fetch() async {
    try {
      final r = await _http
          .get(Uri.parse(_url), headers: {'User-Agent': 'forex-app'})
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) throw StateError('BCB HTTP ${r.statusCode}');
      _last = parse(r.body);
      _fetchedAt = DateTime.now();
      warning = null;
      return _last;
    } catch (_) {
      warning = 'No se pudo actualizar el BCB.';
      return _last;
    }
  }

  static BobRate parse(String html) {
    final value = RegExp(
      r'''class=["'][^"']*\btco-public-value\b[^"']*["'][^>]*>\s*Bs\s*([\d.,]+)\s*/\$us''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    final vigencia = RegExp(
      r'VIGENCIA:\s*([^<]+)',
      caseSensitive: false,
    ).firstMatch(html)?.group(1)?.trim();
    if (value == null || vigencia == null)
      throw const FormatException('Falta la cotización o vigencia');
    _cents(value);
    final table = RegExp(
      r'''<table\b[^>]*class=["'][^"']*\btco-daily-table\b[^"']*["'][^>]*>(.*?)</table>''',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html)?.group(1);
    if (table == null) throw const FormatException('Falta el historial BCB');
    final points = <DateTime, int>{};
    for (final row in RegExp(
      r'<tr\b[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(table)) {
      final cells =
          RegExp(r'<td\b[^>]*>(.*?)</td>', caseSensitive: false, dotAll: true)
              .allMatches(row.group(1)!)
              .map(
                (cell) => cell
                    .group(1)!
                    .replaceAll(RegExp(r'<[^>]*>'), '')
                    .replaceAll('&nbsp;', ' ')
                    .trim(),
              )
              .toList();
      if (cells.isEmpty) continue;
      if (cells.length != 2)
        throw const FormatException('Fila histórica no válida');
      final date = _date(cells[0]);
      final cents = _cents(cells[1]);
      if (points.containsKey(date) && points[date] != cents) {
        throw const FormatException(
          'Cotizaciones distintas para la misma fecha',
        );
      }
      points[date] = cents;
    }
    if (points.isEmpty) throw const FormatException('Historial BCB vacío');
    final history = [
      for (final point in points.entries)
        BobPoint(date: point.key, cents: point.value),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return BobRate(
      value: value,
      vigencia: vigencia,
      date: _date(vigencia),
      history: history,
    );
  }

  static int _cents(String value) {
    final match = RegExp(
      r'^(\d+),(\d{2})$',
    ).firstMatch(value.replaceAll('.', '').trim());
    if (match == null) throw const FormatException('Cotización no válida');
    final cents = int.parse(match[1]!) * 100 + int.parse(match[2]!);
    if (cents <= 0) throw const FormatException('Cotización no válida');
    return cents;
  }

  static DateTime _date(String value) {
    const months = {
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'setiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12,
    };
    final match = RegExp(
      r'(\d{1,2})\s+de\s+([a-z]+)\s+de\s+(\d{4})',
    ).firstMatch(value.toLowerCase());
    if (match == null || months[match[2]] == null)
      throw const FormatException('Fecha BCB no válida');
    final day = int.parse(match[1]!);
    final month = months[match[2]]!;
    final year = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year)
      throw const FormatException('Fecha BCB no válida');
    return date;
  }

  void close() => _http.close();
}
