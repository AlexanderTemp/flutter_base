// Estado del tipo de cambio boliviano (BCB).
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bob_client.dart';

class BobController extends ChangeNotifier {
  BobController({BobClient? client}) : _client = client ?? BobClient();
  final BobClient _client;

  BobRate? rate;
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    rate = await _client.fetch();
    loading = false;
    notifyListeners();
  }

  void start() {
    load();
    // Cambia 1 vez al día; refrescamos cada hora por si cambió la vigencia.
    Timer.periodic(const Duration(hours: 1), (_) => load());
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
