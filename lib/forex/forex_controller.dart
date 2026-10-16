// Estado de la app Forex: carga el feed, aplica filtros (impacto, divisa,
// hoy/semana), auto-refresca en tiempo real y programa pre-avisos.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ff_feed_client.dart';
import 'ff_exception.dart';
import 'ff_models.dart';
import 'economic_alerts.dart';
import 'data/prefs.dart';

enum ForexScope { today, week }

class ForexController extends ChangeNotifier {
  ForexController({FfFeedClient? client}) : _client = client ?? FfFeedClient();

  final FfFeedClient _client;

  /// Cada cuánto re-descarga el feed (el feed cachea 60 s: no bajar de ahí).
  static const Duration refreshEvery = Duration(seconds: 60);

  bool loading = false;
  String? error;
  DateTime? lastUpdated;
  bool showingPrevious = false;
  List<FfEvent> _previous = [];
  DateTime? _previousAt;
  bool _cacheLoaded = false;
  bool _disposed = false;

  bool get canShowPrevious => _all.isEmpty && _previous.isNotEmpty;

  ForexScope scope = ForexScope.today;
  Set<String> impacts = {'high'}; // noticias "fuertes" por defecto
  Set<String> currencies = {}; // vacío = todas

  bool autoRefresh = true;

  List<FfEvent> _all = [];
  Timer? _refreshTimer;
  final _alertTimers = <Timer>[];

  // ─────────────────────────── lecturas derivadas ───────────────────────────

  /// Clasificación original de la fuente, sin los filtros de Próximas.
  List<FfEvent> get calendarEvents =>
      List<FfEvent>.of(_all)..sort((a, b) => a.time.compareTo(b.time));

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
  /// sin aplicar los filtros del usuario. Las más recientes primero.
  List<FfEvent> get highImpactEvents {
    final out = _all.where((e) => e.impact == 'high').toList()
      ..sort((a, b) => b.time.compareTo(a.time));
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
      list = list.where(
        (e) =>
            e.time.year == now.year &&
            e.time.month == now.month &&
            e.time.day == now.day,
      );
    }
    final out = list.toList()..sort((a, b) => a.time.compareTo(b.time));
    return out;
  }

  // ─────────────────────────────── acciones ─────────────────────────────────

  Future<void> load({bool silent = false}) async {
    if (_disposed || loading) return;
    loading = true;
    if (!silent) {
      notifyListeners();
    }
    try {
      await _restorePrevious();
      if (_disposed) return;
      final fresh = await _client.fetchWeek();
      if (_disposed) return;
      final fetchedAt = _client.lastFetchedAt ?? DateTime.now();
      if (_client.warning != null) {
        if (_previousAt == null || fetchedAt.isAfter(_previousAt!)) {
          _previous = fresh;
          _previousAt = fetchedAt;
        }
        error = _client.warning;
        showingPrevious = lastUpdated != null;
      } else {
        _all = fresh;
        currencies.removeWhere((c) => !availableCurrencies.contains(c));
        lastUpdated = fetchedAt;
        _previous = List.of(fresh);
        _previousAt = fetchedAt;
        showingPrevious = false;
        error = null;
        try {
          await refreshAlerts();
        } catch (e) {
          debugPrint('Tradex: no se pudieron configurar las alertas: $e');
        }
        try {
          await Prefs.setCalendarCache(
            jsonEncode({
              'fetchedAt': fetchedAt.toIso8601String(),
              'events': [for (final event in fresh) event.toJson()],
            }),
          );
        } catch (e) {
          debugPrint('Tradex: no se pudo guardar el calendario: $e');
        }
      }
    } catch (e) {
      if (_disposed) return;
      error = e is FfException ? e.message : e.toString();
      showingPrevious = lastUpdated != null;
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _restorePrevious() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      final raw = await Prefs.calendarCache();
      if (raw == null || _disposed) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.parse(data['fetchedAt'] as String).toLocal();
      final events = (data['events'] as List)
          .map((e) => FfEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      _previous = events;
      _previousAt = at;
      notifyListeners();
    } catch (e) {
      debugPrint('Tradex: calendario guardado no disponible: $e');
    }
  }

  void showPreviousData() {
    if (_disposed || !canShowPrevious) return;
    _all = List.of(_previous);
    currencies.removeWhere((c) => !availableCurrencies.contains(c));
    lastUpdated = _previousAt;
    showingPrevious = true;
    // Una copia de otra fecha debe poder verse aunque esté seleccionado «Hoy».
    if (events.isEmpty) scope = ForexScope.week;
    notifyListeners();
  }

  Future<void> start() {
    _applyAutoRefresh();
    return load();
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

  Future<void> refreshAlerts() async {
    for (final t in _alertTimers) {
      t.cancel();
    }
    _alertTimers.clear();
    final options = await Prefs.notificationOptions();
    if (_disposed || !options.alerts || showingPrevious) return;
    await EconomicAlerts.notifyDue(_all);
    if (_disposed) return;
    final now = DateTime.now();
    for (final e in _all.where((e) => e.isHigh)) {
      final fireAt = e.time.subtract(Duration(minutes: options.leadMinutes));
      final delay = fireAt.difference(now);
      if (delay.isNegative) continue;
      if (delay > const Duration(hours: 24)) continue;
      _alertTimers.add(
        Timer(delay, () {
          EconomicAlerts.notifyDue([e]);
        }),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    for (final t in _alertTimers) {
      t.cancel();
    }
    _client.close();
    super.dispose();
  }
}
