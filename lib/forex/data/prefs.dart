// Preferencias persistentes y copias locales de los datos.
import 'package:shared_preferences/shared_preferences.dart';

import 'coins.dart';
import 'notification_options.dart';

class Prefs {
  static Future<NotificationOptions> notificationOptions() async {
    final sp = await SharedPreferences.getInstance();
    // El servicio Android tiene su propio isolate y caché de preferencias.
    await sp.reload();
    final sections = sp.getStringList('notification_sections')?.toSet();
    final minutes = sp.getInt('alert_lead_minutes') ?? 5;
    return NotificationOptions(
      sections: sections ?? const {'prices', 'change', 'bob', 'events'},
      featuredCoin: sp.getString('notification_featured') ?? '',
      alerts: sp.getBool('high_impact_alerts') ?? false,
      leadMinutes: const [0, 5, 15].contains(minutes) ? minutes : 5,
    );
  }

  static Future<void> setNotificationOptions(
    NotificationOptions options,
  ) async {
    if (!options.hasContent ||
        !const [0, 5, 15].contains(options.leadMinutes)) {
      throw ArgumentError('Configuración de notificaciones no válida.');
    }
    final sp = await SharedPreferences.getInstance();
    final saved = await Future.wait([
      sp.setStringList('notification_sections', options.sections.toList()),
      sp.setString('notification_featured', options.featuredCoin),
      sp.setBool('high_impact_alerts', options.alerts),
      sp.setInt('alert_lead_minutes', options.leadMinutes),
    ]);
    if (saved.contains(false)) throw StateError('No se pudo guardar.');
  }

  static const _kCoins = 'selected_coins';

  static Future<List<String>> coins() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kCoins);
    return list ?? List.of(kDefaultCoins);
  }

  static Future<void> setCoins(List<String> ids) async {
    final sp = await SharedPreferences.getInstance();
    if (!await sp.setStringList(_kCoins, ids)) {
      await sp.reload();
      throw StateError('No se pudo guardar la selección.');
    }
  }

  // Caché de precios cripto (para mostrar lo último al abrir / tras un 429).
  static const _kCryptoCache = 'crypto_cache';

  static Future<String?> cryptoCache() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kCryptoCache);
  }

  static Future<void> setCryptoCache(String json) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCryptoCache, json);
  }

  static const _kCalendarCache = 'calendar_cache';

  static Future<String?> calendarCache() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kCalendarCache);
  }

  static Future<void> setCalendarCache(String json) async {
    final sp = await SharedPreferences.getInstance();
    if (!await sp.setString(_kCalendarCache, json)) {
      throw StateError('No se pudo guardar el calendario.');
    }
  }

  static Future<String?> bobCache() async =>
      (await SharedPreferences.getInstance()).getString('bob_cache');

  static Future<void> setBobCache(String json) async {
    if (!await (await SharedPreferences.getInstance()).setString(
      'bob_cache',
      json,
    )) {
      throw StateError('No se pudo guardar el historial BOB.');
    }
  }
}
