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
  bool _disposed = false;

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
    if (_disposed) return;
    prices = prices.where((p) => _ids.contains(p.id)).toList();
    notifyListeners();
    await load();
  }

  Future<void> load({bool silent = false}) async {
    if (_disposed || loading) return;
    loading = true;
    List<String>? ids;
    if (!silent) {
      notifyListeners();
    }
    try {
      await _loadCache();
      final selected = await Prefs.coins();
      if (_disposed) return;
      _ids = selected;
      ids = List<String>.of(selected);
      prices = prices.where((p) => selected.contains(p.id)).toList();
      final fresh = await _client.fetch(ids);
      if (_disposed || !listEquals(ids, _ids)) return;
      if (fresh.isNotEmpty || ids.isEmpty) {
        prices = fresh;
        error = null;
        await Prefs.setCryptoCache(
          jsonEncode(fresh.map((e) => e.toMap()).toList()),
        );
      }
    } catch (e) {
      // Mantenemos los últimos precios; solo marcamos error si no hay ninguno.
      if (!_disposed &&
          (ids == null || listEquals(ids, _ids)) &&
          prices.isEmpty) {
        error = e.toString();
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
        if (ids != null && !listEquals(ids, _ids)) await load(silent: true);
      }
    }
  }

  Future<void> start() {
    _timer = Timer.periodic(refreshEvery, (_) => load(silent: true));
    return reloadSelection();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
