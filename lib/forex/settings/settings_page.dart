// Ajustes: elegir monedas a trackear y activar la notificación fija (Android).
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../data/coins.dart';
import '../data/prefs.dart';
import '../data/notification_options.dart';
import '../ff_notifications.dart';
import '../live/live_notification.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.onCoinsChanged,
    this.onNotificationsChanged,
  });
  final VoidCallback? onCoinsChanged;
  final Future<void> Function()? onNotificationsChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Set<String> _selected = {};
  bool _live = false;
  bool _loaded = false;
  bool _saving = false;
  bool _selectedOnly = false;
  String _query = '';
  NotificationOptions _options = const NotificationOptions();
  String _version = 'No disponible';

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var version = 'No disponible';
    try {
      // shortcut: versión del proyecto; usar metadatos nativos si se sobrescribe con --build-name/--build-number.
      final manifest = await rootBundle.loadString('pubspec.yaml');
      version =
          RegExp(
            r'^version:\s*(\S+)',
            multiLine: true,
          ).firstMatch(manifest)?.group(1) ??
          version;
    } catch (e) {
      debugPrint('Tradex: versión no disponible: $e');
    }
    final coins = await Prefs.coins();
    final options = await Prefs.notificationOptions();
    final live = _isAndroid && await FlutterForegroundTask.isRunningService;
    if (!mounted) return;
    setState(() {
      _selected = coins.toSet();
      _options = options;
      _version = version;
      _live = live;
      _loaded = true;
    });
  }

  Future<void> _toggleCoin(String id) async {
    if (_saving) return;
    final previous = Set<String>.of(_selected);
    setState(() {
      _saving = true;
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    try {
      await Prefs.setCoins(_selected.toList());
      widget.onCoinsChanged?.call();
      if (_isAndroid) {
        await FlutterForegroundTask.saveData(
          key: 'live_coins',
          value: _selected.join(','),
        );
        if (_live) FlutterForegroundTask.sendDataToTask('refresh');
      }
    } catch (_) {
      final stored = await Prefs.coins();
      if (mounted) setState(() => _selected = stored.toSet());
      _snack('No se pudo actualizar la selección. Inténtalo de nuevo.');
      // Conserva lo ya guardado aunque falle la comunicación con el servicio.
      if (setEquals(stored.toSet(), previous)) widget.onCoinsChanged?.call();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleLive(bool on) async {
    if (_saving) return;
    if (on && _options.sections.contains('prices') && _selected.isEmpty) {
      _snack('Selecciona al menos una moneda primero.');
      return;
    }
    setState(() => _saving = true);
    try {
      if (on) {
        await LiveNotifier.start(_selected.toList());
      } else {
        await LiveNotifier.stop();
      }
      final running = await FlutterForegroundTask.isRunningService;
      if (mounted) setState(() => _live = running);
    } catch (e) {
      _snack('No se pudo cambiar la notificación: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveOptions(NotificationOptions options) async {
    if (_saving) return;
    if (!options.hasContent) {
      _snack('Elige al menos un contenido.');
      return;
    }
    setState(() => _saving = true);
    try {
      if (options.alerts &&
          !_options.alerts &&
          !await FfNotifications.instance.requestPermission()) {
        _snack('Permite las notificaciones para activar las alertas.');
        return;
      }
      await Prefs.setNotificationOptions(options);
      if (mounted) setState(() => _options = options);
      await widget.onNotificationsChanged?.call();
      if (_isAndroid && _live) FlutterForegroundTask.sendDataToTask('refresh');
    } catch (_) {
      final stored = await Prefs.notificationOptions();
      if (mounted) setState(() => _options = stored);
      _snack('No se pudo aplicar el cambio.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleSection(String section) {
    final sections = Set<String>.of(_options.sections);
    if (!sections.remove(section)) sections.add(section);
    _saveOptions(_options.copyWith(sections: sections));
  }

  void _snack(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final coins = kCoins.where(
      (c) =>
          (!_selectedOnly || _selected.contains(c.id)) &&
          ('${c.symbol} ${c.id}'.toLowerCase().contains(_query)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.space_dashboard_outlined),
                  title: const Text('Notificación fija'),
                  subtitle: Text(
                    _isAndroid
                        ? 'Resumen en la bandeja.'
                        : 'Disponible en Android.',
                  ),
                  value: _live,
                  onChanged: _isAndroid && !_saving ? _toggleLive : null,
                ),
                ExpansionTile(
                  title: const Text('Contenido del panel'),
                  leading: const Icon(Icons.tune),
                  children: [
                    for (final section in const {
                      'prices': 'Precios',
                      'change': 'Variación 24 h',
                      'bob': 'USD/BOB',
                      'events': 'Eventos',
                    }.entries)
                      CheckboxListTile(
                        dense: true,
                        title: Text(section.value),
                        value: _options.sections.contains(section.key),
                        onChanged:
                            _saving ||
                                (section.key == 'change' &&
                                    !_options.sections.contains('prices'))
                            ? null
                            : (_) => _toggleSection(section.key),
                      ),
                    ListTile(
                      title: const Text('Moneda destacada'),
                      subtitle: DropdownButton<String>(
                        isExpanded: true,
                        value: _selected.contains(_options.featuredCoin)
                            ? _options.featuredCoin
                            : '',
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Primera de mi lista'),
                          ),
                          for (final coin in kCoins.where(
                            (coin) => _selected.contains(coin.id),
                          ))
                            DropdownMenuItem(
                              value: coin.id,
                              child: Text(coin.symbol),
                            ),
                        ],
                        onChanged:
                            _saving || !_options.sections.contains('prices')
                            ? null
                            : (value) {
                                if (value != null)
                                  _saveOptions(
                                    _options.copyWith(featuredCoin: value),
                                  );
                              },
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Alto impacto'),
                  subtitle: const Text('Alertas del calendario.'),
                  value: _options.alerts,
                  onChanged: _saving
                      ? null
                      : (value) =>
                            _saveOptions(_options.copyWith(alerts: value)),
                ),
                if (_options.alerts) ...[
                  ListTile(
                    title: const Text('Avisarme'),
                    trailing: DropdownButton<int>(
                      value: _options.leadMinutes,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('A la hora')),
                        DropdownMenuItem(value: 5, child: Text('5 min antes')),
                        DropdownMenuItem(
                          value: 15,
                          child: Text('15 min antes'),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value != null)
                                _saveOptions(
                                  _options.copyWith(leadMinutes: value),
                                );
                            },
                    ),
                  ),
                  if (_isAndroid)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text('Con la app cerrada, activa el panel.'),
                    ),
                ],
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de Tradex'),
                  subtitle: Text('Versión $_version · Aynicode'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Tradex',
                    applicationVersion: _version,
                    applicationIcon: Image.asset(
                      'assets/branding/tradex.png',
                      width: 48,
                      height: 48,
                    ),
                    applicationLegalese: 'Desarrollado por Aynicode',
                    children: const [
                      SizedBox(height: 16),
                      Text(
                        'Cotizaciones, calendario económico y noticias en un solo lugar.',
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Fuentes: Forex Factory / FairEconomy, CoinGecko, Banco Central de Bolivia, FXStreet e Investing.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu lista de seguimiento',
                  style: t.textStyle.heading4.enhanced(
                    color: t.textColorScheme.primary,
                  ),
                ),
                Text(
                  '${_selected.length} seleccionadas · ${kCoins.length} disponibles',
                  style: t.textStyle.caption.standard(
                    color: t.textColorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar moneda o símbolo…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: !_selectedOnly,
                      onSelected: (_) => setState(() => _selectedOnly = false),
                    ),
                    ChoiceChip(
                      label: Text('Mi lista (${_selected.length})'),
                      selected: _selectedOnly,
                      onSelected: (_) => setState(() => _selectedOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Monedas de la cinta y del panel.',
                  style: t.textStyle.caption.standard(
                    color: t.textColorScheme.secondary,
                  ),
                ),
                if (coins.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No hay monedas con estos filtros.'),
                  ),
                ...coins.map(
                  (c) => CheckboxListTile(
                    dense: true,
                    value: _selected.contains(c.id),
                    onChanged: _saving ? null : (_) => _toggleCoin(c.id),
                    title: Text(c.symbol),
                    subtitle: Text(c.id),
                    secondary: CircleAvatar(
                      child: Text(
                        c.symbol.substring(
                          0,
                          c.symbol.length > 2 ? 2 : c.symbol.length,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
