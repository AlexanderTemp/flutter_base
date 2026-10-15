// Precios cripto en vivo (CoinGecko, gratis y accesible desde Dart) para
// mostrar la "reacción" junto al análisis de las noticias de alto impacto.
import 'dart:convert';

import 'package:http/http.dart' as http;

class CryptoPrice {
  CryptoPrice({required this.id, required this.symbol, required this.usd, required this.change24h});
  final String id;
  final String symbol;
  final double usd;
  final double change24h;
}

class CryptoClient {
  CryptoClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _coins = {
    'bitcoin': 'BTC',
    'ethereum': 'ETH',
    'solana': 'SOL',
  };

  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  Future<List<CryptoPrice>> fetch() async {
    final ids = _coins.keys.join(',');
    final url = 'https://api.coingecko.com/api/v3/simple/price'
        '?ids=$ids&vs_currencies=usd&include_24hr_change=true';
    final r = await _http
        .get(Uri.parse(url), headers: {'User-Agent': _ua, 'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('CoinGecko no disponible (${r.statusCode}).');
    }
    final map = jsonDecode(r.body) as Map<String, dynamic>;
    final out = <CryptoPrice>[];
    for (final entry in _coins.entries) {
      final d = map[entry.key];
      if (d is Map) {
        out.add(CryptoPrice(
          id: entry.key,
          symbol: entry.value,
          usd: (d['usd'] as num?)?.toDouble() ?? 0,
          change24h: (d['usd_24h_change'] as num?)?.toDouble() ?? 0,
        ));
      }
    }
    return out;
  }

  void close() => _http.close();
}
