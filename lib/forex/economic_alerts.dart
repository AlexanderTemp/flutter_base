import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/notification_options.dart';
import 'data/prefs.dart';
import 'ff_models.dart';
import 'ff_notifications.dart';

class EconomicAlerts {
  static Future<void> _pending = Future<void>.value();

  static Iterable<FfEvent> dueEvents(
    List<FfEvent> events,
    NotificationOptions options,
    DateTime now,
  ) => events.where((event) {
    final due = event.time.subtract(Duration(minutes: options.leadMinutes));
    final elapsed = now.difference(due);
    return options.alerts &&
        event.isHigh &&
        !elapsed.isNegative &&
        elapsed < const Duration(minutes: 3);
  });

  static Future<void> notifyDue(
    List<FfEvent> events, {
    bool background = false,
  }) {
    final next = _pending.then(
      (_) => _notifyDue(events, background: background),
    );
    _pending = next;
    return next;
  }

  static Future<void> _notifyDue(
    List<FfEvent> events, {
    required bool background,
  }) async {
    try {
      if (!background &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          await FlutterForegroundTask.isRunningService)
        return;
      final options = await Prefs.notificationOptions();
      if (!options.alerts) return;
      final sp = await SharedPreferences.getInstance();
      final sent = sp.getStringList('economic_alerts_sent') ?? [];
      final now = DateTime.now();
      for (final event in dueEvents(events, options, now)) {
        final key =
            '${event.currency}|${event.name}|${event.time.toUtc().millisecondsSinceEpoch}';
        if (sent.contains(key)) continue;
        final time =
            '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}';
        final remaining = (event.time.difference(now).inSeconds / 60).ceil();
        final shown = await FfNotifications.instance.show(
          id: event.id & 0x7fffffff,
          title: '${event.currency} · ${event.name}',
          body: remaining <= 0
              ? 'Publicación prevista · $time'
              : 'En $remaining min · $time',
        );
        if (!shown) continue;
        sent.add(key);
        await sp.setStringList(
          'economic_alerts_sent',
          sent.length > 256 ? sent.sublist(sent.length - 256) : sent,
        );
      }
    } catch (e) {
      debugPrint('Tradex: no se pudo emitir la alerta: $e');
    }
  }
}
