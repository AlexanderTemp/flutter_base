// Notificaciones locales (sin servidor). Funcionan mientras la app está
// corriendo: escritorio siempre; móvil en primer plano. Ver NOTAS.md.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FfNotifications {
  FfNotifications._();
  static final FfNotifications instance = FfNotifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      const linux = LinuxInitializationSettings(defaultActionName: 'Abrir');
      await _plugin.initialize(const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ));
      _ready = true;
    } catch (e) {
      // En plataformas sin soporte no rompemos la app.
      debugPrint('FfNotifications init falló: $e');
      _ready = false;
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ff_alerts', 'Alertas Forex Factory',
            channelDescription: 'Noticias de alto impacto',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(urgency: LinuxNotificationUrgency.critical),
        ),
      );
    } catch (e) {
      debugPrint('FfNotifications show falló: $e');
    }
  }
}
