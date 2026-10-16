// Precios cripto en vivo (CoinGecko, gratis, accesible desde Dart). Toma la
// lista de ids a consultar (las monedas seleccionadas por el usuario).
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/coins.dart';

class CryptoPrice {
  CryptoPrice({
    required this.id,
    required this.symbol,
    required this.usd,
    required this.change24h,
    required this.decimals,
  });
  final String id;
  final String symbol;
  final double usd;
  final double change24h;
  final int decimals;

  String get priceFmt {
    final s = usd.toStringAsFixed(decimals);
    // separador de miles
    final parts = s.split('.');
    parts[0] = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return parts.join('.');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'symbol': symbol,
    'usd': usd,
    'change24h': change24h,
    'decimals': decimals,
  };

  factory CryptoPrice.fromMap(Map<String, dynamic> m) => CryptoPrice(
    id: m['id'] as String,
    symbol: m['symbol'] as String,
    usd: (m['usd'] as num).toDouble(),
    change24h: (m['change24h'] as num).toDouble(),
    decimals: (m['decimals'] as num).toInt(),
  );
}

class CryptoClient {
  CryptoClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  // Caché en memoria: evita martillear CoinGecko (429) y sirve lo último
  // cuando falla. Compartida por todos los que pidan precios en el proceso.
  static String? _key;
  static DateTime? _at;
  static List<CryptoPrice>? _last;
  static const _dedupe = Duration(seconds: 45);

  Future<List<CryptoPrice>> fetch(List<String> ids) async {
    if (ids.isEmpty) return [];
    final key = ids.join(',');
    final now = DateTime.now();

    // Si pedimos lo mismo hace nada, devolvemos la caché (no llamamos a la API).
    if (_last != null && _key == key && now.difference(_at!) < _dedupe) {
      return _last!;
    }

    try {
      final url = Uri.https('api.coingecko.com', '/api/v3/simple/price', {
        'ids': key,
        'vs_currencies': 'usd',
        'include_24hr_change': 'true',
      });
      final r = await _http
          .get(url, headers: {'User-Agent': _ua, 'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) {
        // 429 u otro: devolvemos lo último conocido en vez de romper.
        if (_last != null && _key == key) return _last!;
        throw Exception('CoinGecko no disponible (${r.statusCode}).');
      }
      final map = jsonDecode(r.body) as Map<String, dynamic>;
      final out = <CryptoPrice>[];
      for (final id in ids) {
        final d = map[id];
        if (d is Map) {
          final price = d['usd'];
          final change = d['usd_24h_change'];
          if (price is! num ||
              !price.isFinite ||
              price <= 0 ||
              change is! num ||
              !change.isFinite)
            continue;
          final coin = coinById(id);
          out.add(
            CryptoPrice(
              id: id,
              symbol: coin?.symbol ?? id.toUpperCase(),
              decimals: coin?.decimals ?? 2,
              usd: price.toDouble(),
              change24h: change.toDouble(),
            ),
          );
        }
      }
      if (out.isEmpty) throw const FormatException('Sin cotizaciones válidas.');
      _last = out;
      _key = key;
      _at = now;
      return out;
    } catch (e) {
      if (_last != null && _key == key) return _last!;
      rethrow;
    }
  }

  void close() => _http.close();
}
