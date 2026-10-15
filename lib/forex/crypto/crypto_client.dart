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
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    return parts.join('.');
  }
}

class CryptoClient {
  CryptoClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  Future<List<CryptoPrice>> fetch(List<String> ids) async {
    if (ids.isEmpty) return [];
    final url = 'https://api.coingecko.com/api/v3/simple/price'
        '?ids=${ids.join(",")}&vs_currencies=usd&include_24hr_change=true';
    final r = await _http.get(Uri.parse(url),
        headers: {'User-Agent': _ua, 'Accept': 'application/json'}).timeout(
        const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('CoinGecko no disponible (${r.statusCode}).');
    }
    final map = jsonDecode(r.body) as Map<String, dynamic>;
    final out = <CryptoPrice>[];
    for (final id in ids) {
      final d = map[id];
      if (d is Map) {
        final coin = coinById(id);
        out.add(CryptoPrice(
          id: id,
          symbol: coin?.symbol ?? id.toUpperCase(),
          decimals: coin?.decimals ?? 2,
          usd: (d['usd'] as num?)?.toDouble() ?? 0,
          change24h: (d['usd_24h_change'] as num?)?.toDouble() ?? 0,
        ));
      }
    }
    return out;
  }

  void close() => _http.close();
}
