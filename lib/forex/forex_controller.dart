// Estado de la pantalla Forex: carga el feed, filtra las rojas y programa
// pre-avisos (notificación local) mientras la app está en primer plano.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ff_feed_client.dart';
import 'ff_models.dart';
import 'ff_notifications.dart';

enum ForexScope { today, week }

class ForexController extends ChangeNotifier {
  ForexController({FfFeedClient? client})
      : _client = client ?? FfFeedClient();

  final FfFeedClient _client;

  /// Minutos de antelación del pre-aviso.
  static const int preMinutes = 5;

  bool loading = false;
  String? error;
  ForexScope scope = ForexScope.today;
  List<FfEvent> _all = [];
  final _timers = <Timer>[];
  final _alerted = <int>{};

  List<FfEvent> get events {
    final now = DateTime.now();
    var red = _all.where((e) => e.isHigh).toList();
    if (scope == ForexScope.today) {
      red = red
          .where((e) =>
              e.time.year == now.year &&
              e.time.month == now.month &&
              e.time.day == now.day)
          .toList();
    }
    red.sort((a, b) => a.time.compareTo(b.time));
    return red;
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _all = await _client.fetchWeek();
      _schedulePreAlerts();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setScope(ForexScope s) {
    scope = s;
    notifyListeners();
  }

  void _schedulePreAlerts() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    final now = DateTime.now();
    for (final e in _all.where((e) => e.isHigh)) {
      if (_alerted.contains(e.id)) continue;
      final fireAt = e.time.subtract(const Duration(minutes: preMinutes));
      final delay = fireAt.difference(now);
      if (delay.isNegative) continue; // ya pasó
      if (delay > const Duration(hours: 24)) continue; // demasiado lejos
      _timers.add(Timer(delay, () {
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
    for (final t in _timers) {
      t.cancel();
    }
    _client.close();
    super.dispose();
  }
}
