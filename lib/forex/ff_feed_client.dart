// Cliente del feed oficial de FairEconomy (el que alimenta el calendario de
// Forex Factory). Devuelve la programación de la semana: título, divisa, hora,
// impacto, forecast y previo. NO trae el valor 'actual' (eso vive en
// /calendar, que Cloudflare bloquea para clientes no-navegador).
//
// Esta es la vía que SÍ funciona desde la app Flutter (probado: HTTP 200).
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ff_models.dart';
import 'ff_client.dart' show FfException;

class FfFeedClient {
  FfFeedClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _url =
      'https://nfs.faireconomy.media/ff_calendar_thisweek.json';
  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  /// Descarga la semana en curso. El feed cachea 60 s: no pidas más seguido.
  Future<List<FfEvent>> fetchWeek() async {
    final r = await _http.get(Uri.parse(_url),
        headers: {'User-Agent': _ua, 'Accept': 'application/json'});
    if (r.statusCode == 429) {
      throw FfException('Vas muy rápido (429). El feed se refresca cada 60 s.');
    }
    if (r.statusCode != 200) {
      throw FfException('Feed no disponible (HTTP ${r.statusCode}).');
    }
    final list = jsonDecode(r.body) as List;
    return [
      for (final e in list) FfEvent.fromFeed(e as Map<String, dynamic>),
    ];
  }

  void close() => _http.close();
}
