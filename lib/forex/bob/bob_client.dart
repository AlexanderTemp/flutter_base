// Tipo de cambio oficial USD/BOB del Banco Central de Bolivia (misma fuente que
// tu waybar bcbrate.py). Página pública, sin key. Actualiza 1 vez al día.
import 'package:http/http.dart' as http;

class BobRate {
  BobRate({required this.value, required this.vigencia});
  final String value; // p.ej. "11,68"
  final String vigencia; // p.ej. "JUEVES 15 DE OCTUBRE DE 2026"
}

class BobClient {
  BobClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _url =
      'https://www.bcb.gob.bo/bcb_tco_publico_ultima_cotizacion.php';

  static BobRate? _last; // sirve lo último si falla (cambia 1 vez/día)

  Future<BobRate?> fetch() async {
    try {
      final r = await _http.get(Uri.parse(_url),
          headers: {'User-Agent': 'forex-app'}).timeout(
          const Duration(seconds: 12));
      if (r.statusCode != 200) return _last;
      final v = RegExp(r'tco-public-value">Bs ([\d,]+)/\$us').firstMatch(r.body);
      if (v == null) return _last;
      final vig = RegExp(r'VIGENCIA:\s*([^<]+)').firstMatch(r.body);
      _last = BobRate(
        value: v.group(1)!,
        vigencia: vig?.group(1)?.trim() ?? '',
      );
      return _last;
    } catch (_) {
      return _last;
    }
  }

  void close() => _http.close();
}
