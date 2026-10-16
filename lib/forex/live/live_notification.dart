// Notificación fija tipo Poweramp (foreground service): muestra los precios de
// tus monedas + boliviano + noticias fuertes de hoy/mañana, y se refresca sola.
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../bob/bob_client.dart';
import '../crypto/crypto_client.dart';
import '../data/coins.dart';
import '../data/prefs.dart';
import '../economic_alerts.dart';
import '../ff_feed_client.dart';
import '../ff_models.dart';
import '../ff_notifications.dart';

const _kCoinsKey = 'live_coins';

class MarketSnapshot {
  MarketSnapshot({
    required this.prices,
    required this.bob,
    required this.events,
    required this.updatedAt,
    required this.selectedCount,
    this.showChanges = true,
  });

  final List<CryptoPrice> prices;
  final BobRate? bob;
  final List<FfEvent> events;
  final DateTime updatedAt;
  final int selectedCount;
  final bool showChanges;

  String get timeLabel => _hhmm(updatedAt);
  String get summary => prices.isEmpty
      ? 'Sin precios disponibles por ahora'
      : '${prices.first.symbol} \$${prices.first.priceFmt}'
            '${showChanges ? " ${prices.first.change24h >= 0 ? "+" : ""}${prices.first.change24h.toStringAsFixed(2)}%" : ""}';
  List<String> get lines => [
    for (final p in prices)
      '${p.symbol}  \$${p.priceFmt}${showChanges ? "  ${p.change24h >= 0 ? "▲" : "▼"} ${p.change24h.abs().toStringAsFixed(2)}%" : ""}',
    if (bob != null) 'USD/BOB  Bs ${bob!.value}',
    for (final e in events) eventLabel(e),
  ];

  String eventLabel(FfEvent e) {
    final today = DateTime(updatedAt.year, updatedAt.month, updatedAt.day);
    final day = DateTime(e.time.year, e.time.month, e.time.day);
    return '${day == today ? "Hoy" : "Mañana"} ${_hhmm(e.time)} · ${e.currency} ${e.name}';
  }

  Map<String, Object?> toMap({required bool ongoing}) => {
    'ongoing': ongoing,
    'time': timeLabel,
    'summary': summary,
    'selectedCount': selectedCount,
    'showChanges': showChanges,
    'prices': [
      for (final p in prices)
        {
          'symbol': p.symbol,
          'price': '\$${p.priceFmt}',
          'change':
              '${p.change24h >= 0 ? "+" : ""}${p.change24h.toStringAsFixed(2)}%',
          'up': p.change24h >= 0,
        },
    ],
    'bob': bob?.value,
    'events': events.map(eventLabel).toList(),
  };

  static String _hhmm(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

/// Mismo contenido para el panel puntual y el servicio en segundo plano.
class LiveContent {
  static Future<MarketSnapshot> load({
    List<String>? coinIds,
    bool background = false,
  }) async {
    final options = await Prefs.notificationOptions();
    String idsCsv;
    try {
      idsCsv =
          await FlutterForegroundTask.getData<String>(key: _kCoinsKey) ??
          kDefaultCoins.join(',');
    } catch (_) {
      // En escritorio el plugin no existe: usamos la selección por defecto.
      idsCsv = kDefaultCoins.join(',');
    }
    final ids = List<String>.of(
      coinIds ?? idsCsv.split(',').where((e) => e.isNotEmpty),
    );
    if (ids.remove(options.featuredCoin)) ids.insert(0, options.featuredCoin);

    final results = await Future.wait([
      options.sections.contains('prices')
          ? _crypto(ids)
          : Future.value(<CryptoPrice>[]),
      options.sections.contains('bob') ? _bob() : Future<BobRate?>.value(null),
      options.sections.contains('events') || options.alerts
          ? _news(background: background)
          : Future.value(<FfEvent>[]),
    ]);
    return MarketSnapshot(
      prices: results[0] as List<CryptoPrice>,
      bob: results[1] as BobRate?,
      events: options.sections.contains('events')
          ? results[2] as List<FfEvent>
          : [],
      updatedAt: DateTime.now(),
      selectedCount: options.sections.contains('prices') ? ids.length : 0,
      showChanges: options.sections.contains('change'),
    );
  }

  static Future<List<CryptoPrice>> _crypto(List<String> ids) async {
    final c = CryptoClient();
    try {
      return await c.fetch(ids);
    } catch (_) {
      return [];
    } finally {
      c.close();
    }
  }

  static Future<BobRate?> _bob() async {
    final b = BobClient();
    try {
      return await b.fetch();
    } finally {
      b.close();
    }
  }

  static Future<List<FfEvent>> _news({required bool background}) async {
    final f = FfFeedClient();
    try {
      final all = await f.fetchWeek();
      if (f.warning == null)
        await EconomicAlerts.notifyDue(all, background: background);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final end = DateTime(today.year, today.month, today.day + 2);
      final high =
          all
              .where(
                (e) =>
                    e.isHigh && !e.time.isBefore(now) && e.time.isBefore(end),
              )
              .toList()
            ..sort((a, b) => a.time.compareTo(b.time));
      return high.take(2).toList();
    } catch (_) {
      return [];
    } finally {
      f.close();
    }
  }
}

class MarketNotification {
  static const _channel = MethodChannel('tradex/notifications');

  static Future<void> show(
    MarketSnapshot snapshot, {
    bool ongoing = false,
  }) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (!ongoing &&
          await FlutterForegroundTask.checkNotificationPermission() !=
              NotificationPermission.granted) {
        final permission =
            await FlutterForegroundTask.requestNotificationPermission();
        if (permission != NotificationPermission.granted) {
          throw StateError('Permiso de notificaciones denegado.');
        }
      }
      await _channel.invokeMethod<void>(
        'showMarket',
        snapshot.toMap(ongoing: ongoing),
      );
    } else {
      await FfNotifications.instance.show(
        id: 2,
        title: 'Cotizaciones',
        body: snapshot.lines.isEmpty
            ? 'Sin datos por ahora.'
            : snapshot.lines.join('\n'),
      );
    }
  }
}

/// Punto de entrada del isolate del servicio.
@pragma('vm:entry-point')
void startLiveCallback() {
  FlutterForegroundTask.setTaskHandler(LiveTaskHandler());
}

class LiveTaskHandler extends TaskHandler {
  bool _updating = false;
  bool _stopped = false;
  Future<void> _update() async {
    if (_updating) return;
    _updating = true;
    try {
      final snapshot = await LiveContent.load(background: true);
      if (!_stopped) await MarketNotification.show(snapshot, ongoing: true);
    } catch (e) {
      debugPrint('Tradex: no se pudo actualizar el panel: $e');
    } finally {
      _updating = false;
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _stopped = false;
    await _update();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _update();
  }

  @override
  void onReceiveData(Object data) {
    if (data == 'refresh') _update();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _stopped = true;
  }
}

/// API de la app para encender/apagar la notificación fija.
class LiveNotifier {
  static void configure() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'forex_live',
        channelName: 'Cotizaciones en vivo',
        channelDescription: 'Tu resumen de mercado.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(120000), // cada 120 s
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
      key: _kCoinsKey,
      value: coinIds.join(','),
    );
    final result = await FlutterForegroundTask.startService(
      serviceId: 100,
      notificationTitle: 'Cargando mercado',
      notificationText: 'Un momento…',
      callback: startLiveCallback,
    );
    if (result is ServiceRequestFailure) throw result.error;
  }

  static Future<void> stop() async {
    final result = await FlutterForegroundTask.stopService();
    if (result is ServiceRequestFailure) throw result.error;
  }

  static Future<void> _ensurePermissions() async {
    final np = await FlutterForegroundTask.checkNotificationPermission();
    if (np != NotificationPermission.granted) {
      final permission =
          await FlutterForegroundTask.requestNotificationPermission();
      if (permission != NotificationPermission.granted) {
        throw StateError('Permite las notificaciones de Tradex en Android.');
      }
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }
}
