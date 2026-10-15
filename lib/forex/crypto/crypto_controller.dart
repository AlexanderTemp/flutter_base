// Estado de precios cripto (para la barra y la pestaña de Análisis). Usa las
// monedas seleccionadas en Settings, cachea la última versión y sirve lo último
// si hay 429 (nunca se queda sin datos una vez cargó).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/prefs.dart';
import 'crypto_client.dart';

class CryptoController extends ChangeNotifier {
  CryptoController({CryptoClient? client}) : _client = client ?? CryptoClient();

  final CryptoClient _client;
  static const Duration refreshEvery = Duration(seconds: 180);

  bool loading = false;
  String? error;
  List<CryptoPrice> prices = [];
  List<String> _ids = [];
  Timer? _timer;
  bool _cacheLoaded = false;

  Future<void> _loadCache() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final raw = await Prefs.cryptoCache();
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => CryptoPrice.fromMap(e as Map<String, dynamic>))
            .toList();
        if (prices.isEmpty) prices = list;
      }
    } catch (_) {}
  }

  Future<void> reloadSelection() async {
    _ids = await Prefs.coins();
    await load();
  }

  Future<void> load({bool silent = false}) async {
    await _loadCache();
    if (_ids.isEmpty) _ids = await Prefs.coins();
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      final fresh = await _client.fetch(_ids);
      if (fresh.isNotEmpty) {
        prices = fresh;
        error = null;
        Prefs.setCryptoCache(jsonEncode(fresh.map((e) => e.toMap()).toList()));
      }
    } catch (e) {
      // Mantenemos los últimos precios; solo marcamos error si no hay ninguno.
      if (prices.isEmpty) error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void start() {
    reloadSelection();
    _timer = Timer.periodic(refreshEvery, (_) => load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
