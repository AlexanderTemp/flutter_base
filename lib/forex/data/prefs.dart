// Preferencias persistentes (shared_preferences): monedas seleccionadas y si la
// notificación fija está activa.
import 'package:shared_preferences/shared_preferences.dart';

import 'coins.dart';

class Prefs {
  static const _kCoins = 'selected_coins';
  static const _kLive = 'live_notification';

  static Future<List<String>> coins() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kCoins);
    return (list == null || list.isEmpty) ? List.of(kDefaultCoins) : list;
  }

  static Future<void> setCoins(List<String> ids) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kCoins, ids);
  }

  static Future<bool> liveOn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kLive) ?? false;
  }

  static Future<void> setLive(bool on) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLive, on);
  }
}
