// Estado de la app Forex: carga el feed, aplica filtros (impacto, divisa,
// hoy/semana), auto-refresca en tiempo real y programa pre-avisos.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ff_feed_client.dart';
import 'ff_models.dart';
import 'ff_notifications.dart';

enum ForexScope { today, week }

class ForexController extends ChangeNotifier {
  ForexController({FfFeedClient? client}) : _client = client ?? FfFeedClient();

  final FfFeedClient _client;

  /// Minutos de antelación del pre-aviso.
  static const int preMinutes = 5;

  /// Cada cuánto re-descarga el feed (el feed cachea 60 s: no bajar de ahí).
  static const Duration refreshEvery = Duration(seconds: 60);

  bool loading = false;
  String? error;
  DateTime? lastUpdated;

  ForexScope scope = ForexScope.today;
  Set<String> impacts = {'high'}; // noticias "fuertes" por defecto
  Set<String> currencies = {}; // vacío = todas

  bool autoRefresh = true;

  List<FfEvent> _all = [];
  Timer? _refreshTimer;
  final _alertTimers = <Timer>[];
  final _alerted = <int>{};

  // ─────────────────────────── lecturas derivadas ───────────────────────────

  /// Divisas disponibles (según los impactos elegidos), para los chips.
  List<String> get availableCurrencies {
    final set = <String>{};
    for (final e in _all) {
      if (impacts.contains(e.impact)) set.add(e.currency);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Todas las de alto impacto de la semana (para la pestaña de Análisis),
  /// sin aplicar los filtros del usuario. Ordenadas por hora.
  List<FfEvent> get highImpactEvents {
    final out = _all.where((e) => e.impact == 'high').toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  /// Eventos ya filtrados y ordenados por hora.
  List<FfEvent> get events {
    final now = DateTime.now();
    var list = _all.where((e) => impacts.contains(e.impact));
    if (currencies.isNotEmpty) {
      list = list.where((e) => currencies.contains(e.currency));
    }
    if (scope == ForexScope.today) {
      list = list.where((e) =>
          e.time.year == now.year &&
          e.time.month == now.month &&
          e.time.day == now.day);
    }
    final out = list.toList()..sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  // ─────────────────────────────── acciones ─────────────────────────────────

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      _all = await _client.fetchWeek();
      lastUpdated = DateTime.now();
      error = null;
      _schedulePreAlerts();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void start() {
    load();
    _applyAutoRefresh();
  }

  void setScope(ForexScope s) {
    scope = s;
    notifyListeners();
  }

  void toggleImpact(String impact) {
    if (impacts.contains(impact)) {
      if (impacts.length > 1) impacts.remove(impact); // nunca vacío
    } else {
      impacts.add(impact);
    }
    // Si una divisa filtrada ya no existe en los nuevos impactos, la soltamos.
    currencies.removeWhere((c) => !availableCurrencies.contains(c));
    notifyListeners();
  }

  void toggleCurrency(String currency) {
    if (currencies.contains(currency)) {
      currencies.remove(currency);
    } else {
      currencies.add(currency);
    }
    notifyListeners();
  }

  void clearCurrencies() {
    currencies.clear();
    notifyListeners();
  }

  void setAutoRefresh(bool on) {
    autoRefresh = on;
    _applyAutoRefresh();
    notifyListeners();
  }

  void _applyAutoRefresh() {
    _refreshTimer?.cancel();
    if (autoRefresh) {
      _refreshTimer = Timer.periodic(refreshEvery, (_) => load(silent: true));
    }
  }

  // ─────────────────────────────── pre-avisos ───────────────────────────────

  void _schedulePreAlerts() {
    for (final t in _alertTimers) {
      t.cancel();
    }
    _alertTimers.clear();
    final now = DateTime.now();
    for (final e in _all.where((e) => impacts.contains(e.impact))) {
      if (_alerted.contains(e.id)) continue;
      final fireAt = e.time.subtract(const Duration(minutes: preMinutes));
      final delay = fireAt.difference(now);
      if (delay.isNegative) continue;
      if (delay > const Duration(hours: 24)) continue;
      _alertTimers.add(Timer(delay, () {
        _alerted.add(e.id);
        final hhmm =
            '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}';
        FfNotifications.instance.show(
          id: e.id & 0x7fffffff,
          title: '⏰ ~$preMinutes min: ${e.currency} ${e.name}',
          body: 'Noticia de alto impacto a las $hhmm · '
              'forecast ${e.forecast.isEmpty ? "-" : e.forecast} · '
              'previo ${e.previous.isEmpty ? "-" : e.previous}',
        );
      }));
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    for (final t in _alertTimers) {
      t.cancel();
    }
    _client.close();
    super.dispose();
  }
}
