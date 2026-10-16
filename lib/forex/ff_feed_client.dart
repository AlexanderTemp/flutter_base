// Cliente del feed oficial de FairEconomy (el que alimenta el calendario de
// Forex Factory). Devuelve la programación de la semana: título, divisa, hora,
// impacto, forecast y previo. NO trae el valor 'actual' (eso vive en
// /calendar, que Cloudflare bloquea para clientes no-navegador).
//
// Esta es la vía que SÍ funciona desde la app Flutter (probado: HTTP 200).
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ff_models.dart';
import 'ff_exception.dart';

class FfFeedClient {
  FfFeedClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  String? warning;
  DateTime? get lastFetchedAt => _at;

  static const _url = 'https://nfs.faireconomy.media/ff_calendar_thisweek.json';
  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  // Caché en memoria: sirve lo último cuando hay 429 y evita llamadas seguidas.
  static DateTime? _at;
  static List<FfEvent>? _last;
  static const _dedupe = Duration(seconds: 60);

  /// Descarga la semana en curso. El feed cachea 60 s: no pidas más seguido.
  Future<List<FfEvent>> fetchWeek() async {
    final now = DateTime.now();
    if (_last != null && _at != null && now.difference(_at!) < _dedupe) {
      warning = null;
      return _last!;
    }
    try {
      final r = await _http
          .get(
            Uri.parse(_url),
            headers: {'User-Agent': _ua, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) {
        throw FfException(
          r.statusCode == 429
              ? 'El servicio ha limitado las consultas temporalmente.'
              : 'Feed no disponible (HTTP ${r.statusCode}).',
        );
      }
      final list = jsonDecode(r.body) as List;
      final events = [
        for (final e in list) FfEvent.fromFeed(e as Map<String, dynamic>),
      ];
      _last = events;
      _at = now;
      warning = null;
      return events;
    } catch (e) {
      warning = e is FfException ? e.message : e.toString();
      if (_last != null) return _last!;
      rethrow;
    }
  }

  void close() => _http.close();
}
