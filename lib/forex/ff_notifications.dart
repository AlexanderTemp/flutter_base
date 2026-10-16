// Notificaciones locales (sin servidor). Funcionan mientras la app está
// corriendo: escritorio siempre; móvil en primer plano. Ver NOTAS.md.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FfNotifications {
  FfNotifications._();
  static final FfNotifications instance = FfNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('ic_tradex_notification');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linux = LinuxInitializationSettings(defaultActionName: 'Abrir');
      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
          linux: linux,
        ),
      );
      _ready = true;
    } catch (e) {
      // En plataformas sin soporte no rompemos la app.
      debugPrint('FfNotifications init falló: $e');
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null)
      return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null)
      return await ios.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (mac != null)
      return await mac.requestPermissions(
            alert: true,
            sound: true,
            badge: true,
          ) ??
          false;
    return true;
  }

  Future<bool> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    if (!_ready) return false;
    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'ff_alerts',
            'Tradex · Alertas económicas',
            channelDescription: 'Noticias de alto impacto',
            importance: Importance.max,
            priority: Priority.high,
            onlyAlertOnce: true,
            icon: 'ic_tradex_notification',
            color: const Color(0xFF5268EB),
            subText: 'Alto impacto',
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
            ),
          ),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
          linux: const LinuxNotificationDetails(
            urgency: LinuxNotificationUrgency.critical,
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('FfNotifications show falló: $e');
      return false;
    }
  }
}
