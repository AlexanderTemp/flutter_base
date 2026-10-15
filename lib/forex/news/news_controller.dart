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

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final data = await _client.fetchAll();
      if (data.isNotEmpty) items = data;
      lastUpdated = DateTime.now();
      if (data.isEmpty && items.isEmpty) {
        error = 'No se pudieron cargar noticias ahora mismo.';
      } else {
        error = null;
      }
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
