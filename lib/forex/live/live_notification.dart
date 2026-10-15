// Notificación fija tipo Poweramp (foreground service): muestra los precios de
// tus monedas + boliviano + noticias fuertes de hoy/mañana, y se refresca sola.
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../bob/bob_client.dart';
import '../crypto/crypto_client.dart';
import '../data/coins.dart';
import '../ff_feed_client.dart';
import '../ff_models.dart';

const _kCoinsKey = 'live_coins';

/// Construye el texto multilínea de la notificación. Standalone: también se usa
/// dentro del isolate del servicio en segundo plano.
class LiveContent {
  static Future<String> build() async {
    String idsCsv;
    try {
      idsCsv = await FlutterForegroundTask.getData<String>(key: _kCoinsKey) ??
          kDefaultCoins.join(',');
    } catch (_) {
      // En escritorio el plugin no existe: usamos la selección por defecto.
      idsCsv = kDefaultCoins.join(',');
    }
    final ids = idsCsv.split(',').where((e) => e.isNotEmpty).toList();

    final results = await Future.wait([
      _crypto(ids),
      _bob(),
      _news(),
    ]);
    final lines = <String>[];
    if ((results[0] as String).isNotEmpty) lines.add(results[0] as String);
    if ((results[1] as String).isNotEmpty) lines.add(results[1] as String);
    lines.addAll(results[2] as List<String>);
    return lines.isEmpty ? 'Sin datos por ahora.' : lines.join('\n');
  }

  static Future<String> _crypto(List<String> ids) async {
    final c = CryptoClient();
    try {
      final prices = await c.fetch(ids);
      return prices
          .map((p) =>
              '${p.symbol} \$${p.priceFmt} ${p.change24h >= 0 ? "▲" : "▼"}${p.change24h.abs().toStringAsFixed(1)}%')
          .join('   ');
    } catch (_) {
      return '';
    } finally {
      c.close();
    }
  }

  static Future<String> _bob() async {
    final b = BobClient();
    try {
      final r = await b.fetch();
      return r == null ? '' : 'BOB Bs ${r.value}/\$us';
    } finally {
      b.close();
    }
  }

  static Future<List<String>> _news() async {
    final f = FfFeedClient();
    try {
      final all = await f.fetchWeek();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      String fmt(List<FfEvent> evs) => evs
          .take(4)
          .map((e) =>
              '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')} ${e.currency} ${e.name}')
          .join(' · ');
      final high = all.where((e) => e.isHigh).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
      final todays = high.where((e) => _sameDay(e.time, today)).toList();
      final tmrw = high.where((e) => _sameDay(e.time, tomorrow)).toList();
      final out = <String>[];
      if (todays.isNotEmpty) out.add('🔴 Hoy: ${fmt(todays)}');
      if (tmrw.isNotEmpty) out.add('🔴 Mañana: ${fmt(tmrw)}');
      return out;
    } catch (_) {
      return [];
    } finally {
      f.close();
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Punto de entrada del isolate del servicio.
@pragma('vm:entry-point')
void startLiveCallback() {
  FlutterForegroundTask.setTaskHandler(LiveTaskHandler());
}

class LiveTaskHandler extends TaskHandler {
  Future<void> _update() async {
    final text = await LiveContent.build();
    FlutterForegroundTask.updateService(
      notificationTitle: 'Forex + Cripto',
      notificationText: text,
    );
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _update();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _update();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// API de la app para encender/apagar la notificación fija.
class LiveNotifier {
  static void configure() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'forex_live',
        channelName: 'Forex en vivo',
        channelDescription: 'Precios y noticias fuertes, siempre visibles.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000), // cada 60 s
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(List<String> coinIds) async {
    await _ensurePermissions();
    await FlutterForegroundTask.saveData(
        key: _kCoinsKey, value: coinIds.join(','));
    await FlutterForegroundTask.startService(
      serviceId: 100,
      notificationTitle: 'Forex + Cripto',
      notificationText: 'Cargando…',
      callback: startLiveCallback,
    );
  }

  static Future<void> stop() => FlutterForegroundTask.stopService();

  static Future<void> _ensurePermissions() async {
    final np = await FlutterForegroundTask.checkNotificationPermission();
    if (np != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }
}
