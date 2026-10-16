// Estado del tipo de cambio boliviano (BCB).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'bob_client.dart';
import '../data/prefs.dart';

class BobController extends ChangeNotifier {
  BobController({BobClient? client}) : _client = client ?? BobClient();
  final BobClient _client;

  BobRate? rate;
  bool loading = false;
  String? error;
  bool showingPrevious = false;
  DateTime? lastUpdated;
  bool _cacheLoaded = false;
  Timer? _timer;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed || loading) return;
    loading = true;
    notifyListeners();
    try {
      if (!_cacheLoaded) {
        _cacheLoaded = true;
        try {
          final raw = await Prefs.bobCache();
          if (raw != null && !_disposed) {
            final cache = jsonDecode(raw) as Map<String, dynamic>;
            rate = BobRate.fromJson(cache['rate'] as Map<String, dynamic>);
            lastUpdated = DateTime.parse(
              cache['fetchedAt'] as String,
            ).toLocal();
            showingPrevious = true;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Tradex: copia BOB no disponible: $e');
        }
      }
      if (_disposed) return;
      final fresh = await _client.fetch();
      if (_disposed) return;
      error = _client.warning;
      if (fresh != null && (error == null || rate == null)) rate = fresh;
      showingPrevious = (fresh == null || error != null) && rate != null;
      if (fresh != null && error == null) {
        lastUpdated = _client.lastFetchedAt ?? DateTime.now();
        try {
          await Prefs.setBobCache(
            jsonEncode({
              'fetchedAt': lastUpdated!.toIso8601String(),
              'rate': fresh.toJson(),
            }),
          );
        } catch (e) {
          debugPrint('Tradex: no se pudo guardar el historial BOB: $e');
        }
      } else {
        error ??= 'Sin cotización disponible.';
      }
    } catch (e) {
      if (!_disposed) {
        error = 'No se pudo actualizar el BCB.';
        showingPrevious = rate != null;
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> start() {
    // Cambia 1 vez al día; refrescamos cada hora por si cambió la vigencia.
    _timer = Timer.periodic(const Duration(hours: 1), (_) => load());
    return load();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
