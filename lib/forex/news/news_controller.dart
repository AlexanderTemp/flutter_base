// Estado de la pestaña de noticias: carga RSS y auto-refresca.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'news_client.dart';
import 'news_models.dart';

class NewsController extends ChangeNotifier {
  NewsController({NewsClient? client}) : _client = client ?? NewsClient();

  final NewsClient _client;
  static const Duration refreshEvery = Duration(minutes: 3);

  bool loading = false;
  String? error;
  DateTime? lastUpdated;
  List<NewsItem> items = [];
  Timer? _timer;
  bool _disposed = false;

  Future<void> load({bool silent = false}) async {
    if (_disposed || loading) return;
    loading = true;
    if (!silent) {
      error = null;
      notifyListeners();
    }
    try {
      final data = await _client.fetchAll();
      if (_disposed) return;
      if (data.isEmpty) {
        error = 'No se pudieron cargar noticias ahora mismo.';
      } else {
        items = data;
        lastUpdated = DateTime.now();
        error = null;
      }
    } catch (e) {
      if (!_disposed) error = e.toString();
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> start() {
    _timer = Timer.periodic(refreshEvery, (_) => load(silent: true));
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
