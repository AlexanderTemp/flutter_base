// Cliente de Forex Factory. Lee el calendario (noticias rojas incluidas) y el
// detalle de cada evento desde las mismas fuentes que usa la web:
//   - /calendar  (bloque calendarComponentStates: actual/forecast/previous)
//   - /calendar/details/0-ID  (specs: Usual Effect, Why Traders Care, history)
//
// Dart puro (package:http). Sin navegador, sin IA, sin API keys.
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ff_models.dart';

class FfClient {
  FfClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  String? _cookie; // cookie de Cloudflare capturada del primer GET

  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';
  static const _base = 'https://www.forexfactory.com';

  Map<String, String> get _headers => {
        'User-Agent': _ua,
        'Accept-Language': 'en-US,en;q=0.9',
        if (_cookie != null) 'Cookie': _cookie!,
      };

  void _captureCookie(http.Response r) {
    final sc = r.headers['set-cookie'];
    if (sc != null && sc.isNotEmpty) {
      // Nos quedamos con el par nombre=valor de cada cookie.
      _cookie = sc
          .split(RegExp(r',(?=[^ ;]+=)'))
          .map((c) => c.split(';').first.trim())
          .join('; ');
    }
  }

  /// Descarga y parsea el calendario de la semana en curso.
  Future<List<FfEvent>> fetchCalendar() async {
    final r = await _http.get(Uri.parse('$_base/calendar'), headers: _headers);
    if (r.statusCode == 403 || r.statusCode == 429) {
      throw FfException('Bloqueo temporal de Forex Factory (${r.statusCode}).');
    }
    if (r.statusCode != 200) {
      throw FfException('Respuesta inesperada ${r.statusCode} del calendario.');
    }
    _captureCookie(r);
    return parseEvents(r.body);
  }

  /// Descarga el detalle (specs + history) de un evento.
  Future<FfDetail> fetchDetail(int eventId) async {
    final r = await _http.get(
      Uri.parse('$_base/calendar/details/0-$eventId'),
      headers: {..._headers, 'X-Requested-With': 'XMLHttpRequest'},
    );
    if (r.statusCode != 200) {
      return FfDetail(specs: {}, history: []);
    }
    final data = (jsonDecode(r.body)['data'] ?? {}) as Map<String, dynamic>;

    final specs = <String, String>{};
    for (final s in (data['specs'] as List? ?? [])) {
      final title = _stripTags((s['title'] ?? '').toString()).trim();
      final val = _unescape(_stripTags((s['html'] ?? '').toString())).trim();
      if (title.isNotEmpty) specs[title] = val;
    }

    final history = <FfHistoryPoint>[];
    final hist = data['history'];
    if (hist is Map && hist['events'] is List) {
      for (final e in hist['events']) {
        history.add(FfHistoryPoint.fromJson(e as Map<String, dynamic>));
      }
    }
    return FfDetail(specs: specs, history: history);
  }

  void close() => _http.close();

  // ─────────────────── parseo del blob calendarComponentStates ──────────────
  /// Extrae todos los eventos del HTML de /calendar.
  static List<FfEvent> parseEvents(String html) {
    final events = <FfEvent>[];
    final seen = <int>{};
    const key = '"events":';
    var pos = 0;
    while (true) {
      final i = html.indexOf(key, pos);
      if (i == -1) break;
      final arrStart = html.indexOf('[', i);
      if (arrStart == -1) break;
      final arr = _balanced(html, arrStart, '[', ']');
      pos = arrStart + arr.length;
      final list = jsonDecode(arr) as List;
      for (final raw in list) {
        final e = raw as Map<String, dynamic>;
        final id = (e['id'] as num?)?.toInt();
        if (id == null || seen.contains(id)) continue;
        if (!e.containsKey('impactName') || !e.containsKey('actual')) continue;
        seen.add(id);
        events.add(FfEvent.fromJson(e));
      }
    }
    return events;
  }

  /// Devuelve la subcadena balanceada que empieza en [start] con [open].
  static String _balanced(String s, int start, String open, String close) {
    final o = open.codeUnitAt(0), c = close.codeUnitAt(0), q = '"'.codeUnitAt(0);
    final bs = r'\'.codeUnitAt(0);
    var depth = 0, j = start;
    var inStr = false, esc = false;
    while (j < s.length) {
      final ch = s.codeUnitAt(j);
      if (inStr) {
        if (esc) {
          esc = false;
        } else if (ch == bs) {
          esc = true;
        } else if (ch == q) {
          inStr = false;
        }
      } else {
        if (ch == q) {
          inStr = true;
        } else if (ch == o) {
          depth++;
        } else if (ch == c) {
          depth--;
          if (depth == 0) return s.substring(start, j + 1);
        }
      }
      j++;
    }
    throw FfException('Delimitador sin cerrar al parsear el calendario.');
  }

  static String _stripTags(String h) =>
      h.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ');

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll(r'\/', '/');
}

class FfException implements Exception {
  FfException(this.message);
  final String message;
  @override
  String toString() => 'FfException: $message';
}
