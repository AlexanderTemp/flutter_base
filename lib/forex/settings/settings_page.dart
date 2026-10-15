// Ajustes: elegir monedas a trackear y activar la notificación fija (Android).
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../data/coins.dart';
import '../data/prefs.dart';
import '../live/live_notification.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onCoinsChanged});
  final VoidCallback? onCoinsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Set<String> _selected = {};
  bool _live = false;
  bool _loaded = false;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final coins = await Prefs.coins();
    final live = await Prefs.liveOn();
    setState(() {
      _selected = coins.toSet();
      _live = live;
      _loaded = true;
    });
  }

  Future<void> _toggleCoin(String id) async {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    await Prefs.setCoins(_selected.toList());
    // Si el servicio corre, que tome las nuevas monedas en el próximo ciclo.
    await FlutterForegroundTask.saveData(
        key: 'live_coins', value: _selected.join(','));
    widget.onCoinsChanged?.call();
  }

  Future<void> _toggleLive(bool on) async {
    if (on && _selected.isEmpty) {
      _snack('Selecciona al menos una moneda primero.');
      return;
    }
    setState(() => _live = on);
    await Prefs.setLive(on);
    if (on) {
      await LiveNotifier.start(_selected.toList());
    } else {
      await LiveNotifier.stop();
    }
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('Monedas a trackear',
                    style: t.textStyle.heading4
                        .enhanced(color: t.textColorScheme.primary)),
                Text('Se muestran en la barra, el análisis y la notificación.',
                    style: t.textStyle.caption
                        .standard(color: t.textColorScheme.secondary)),
                const SizedBox(height: 8),
                ...kCoins.map((c) => CheckboxListTile(
                      dense: true,
                      value: _selected.contains(c.id),
                      onChanged: (_) => _toggleCoin(c.id),
                      title: Text('${c.symbol}  ·  ${c.id}'),
                    )),
                const Divider(height: 24),
                Text('Notificación fija',
                    style: t.textStyle.heading4
                        .enhanced(color: t.textColorScheme.primary)),
                SwitchListTile(
                  title: const Text('Mantener precios + noticias en la barra'),
                  subtitle: Text(_isAndroid
                      ? 'Tipo Poweramp: siempre visible y se actualiza sola.'
                      : 'Disponible en Android.'),
                  value: _live,
                  onChanged: _isAndroid ? _toggleLive : null,
                ),
                if (_isAndroid)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Si tu Poco la mata, acepta ignorar la optimización de '
                      'batería cuando lo pida.',
                      style: t.textStyle.caption
                          .standard(color: t.textColorScheme.tertiary),
                    ),
                  ),
              ],
            ),
    );
  }
}
