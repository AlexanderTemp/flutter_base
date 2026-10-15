// Estado de precios cripto (para la barra y la pestaña de Análisis). Usa las
// monedas seleccionadas en Settings.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/prefs.dart';
import 'crypto_client.dart';

class CryptoController extends ChangeNotifier {
  CryptoController({CryptoClient? client}) : _client = client ?? CryptoClient();

  final CryptoClient _client;
  static const Duration refreshEvery = Duration(seconds: 90);

  bool loading = false;
  String? error;
  List<CryptoPrice> prices = [];
  List<String> _ids = [];
  Timer? _timer;

  Future<void> reloadSelection() async {
    _ids = await Prefs.coins();
    await load();
  }

  Future<void> load({bool silent = false}) async {
    if (_ids.isEmpty) _ids = await Prefs.coins();
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      prices = await _client.fetch(_ids);
      error = null;
    } catch (e) {
      error = e.toString();
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
