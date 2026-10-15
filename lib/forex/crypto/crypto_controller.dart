// Estado de precios cripto (para la pestaña de Análisis).
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'crypto_client.dart';

class CryptoController extends ChangeNotifier {
  CryptoController({CryptoClient? client}) : _client = client ?? CryptoClient();

  final CryptoClient _client;
  static const Duration refreshEvery = Duration(seconds: 90);

  bool loading = false;
  String? error;
  List<CryptoPrice> prices = [];
  Timer? _timer;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }
    try {
      prices = await _client.fetch();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void start() {
    load();
    _timer = Timer.periodic(refreshEvery, (_) => load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
