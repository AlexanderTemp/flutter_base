// Shell de la app Forex: 3 pestañas (Próximas, Noticias, Análisis) + ajustes.
import 'package:flutter/material.dart';

import 'analysis/analysis_view.dart';
import 'bob/bob_controller.dart';
import 'calendar_view.dart';
import 'crypto/crypto_controller.dart';
import 'ff_notifications.dart';
import 'forex_controller.dart';
import 'live/live_notification.dart';
import 'news/news_controller.dart';
import 'news/news_view.dart';
import 'settings/settings_page.dart';

class ForexHomePage extends StatefulWidget {
  const ForexHomePage({super.key, required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<ForexHomePage> createState() => _ForexHomePageState();
}

class _ForexHomePageState extends State<ForexHomePage> {
  final _forex = ForexController();
  final _news = NewsController();
  final _crypto = CryptoController();
  final _bob = BobController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    FfNotifications.instance.init();
    for (final l in [_forex, _news, _crypto, _bob]) {
      l.addListener(_onChange);
    }
    _forex.start();
    _news.start();
    _crypto.start();
    _bob.start();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final l in [_forex, _news, _crypto, _bob]) {
      l.removeListener(_onChange);
      l.dispose();
    }
    super.dispose();
  }

  static const _titles = ['Próximas', 'Noticias', 'Análisis'];

  Future<void> _showPricesNow() async {
    final text = await LiveContent.build();
    await FfNotifications.instance.show(
        id: 2, title: 'Forex + Cripto', body: text);
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsPage(
        onCoinsChanged: () => _crypto.reloadSelection(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forex · ${_titles[_tab]}'),
        actions: _actions(),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          CalendarView(controller: _forex, crypto: _crypto, bob: _bob),
          NewsView(controller: _news),
          AnalysisView(forex: _forex, crypto: _crypto),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'Próximas'),
          NavigationDestination(
              icon: Icon(Icons.article_outlined),
              selectedIcon: Icon(Icons.article),
              label: 'Noticias'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Análisis'),
        ],
      ),
    );
  }

  List<Widget> _actions() {
    final common = [
      IconButton(
        tooltip: 'Ver precios ahora',
        icon: const Icon(Icons.price_change_outlined),
        onPressed: _showPricesNow,
      ),
      IconButton(
        tooltip: 'Cambiar tema',
        icon: const Icon(Icons.contrast),
        onPressed: widget.onToggleTheme,
      ),
      IconButton(
        tooltip: 'Ajustes',
        icon: const Icon(Icons.settings_outlined),
        onPressed: _openSettings,
      ),
    ];
    switch (_tab) {
      case 0:
        return [
          IconButton(
            tooltip:
                _forex.autoRefresh ? 'Auto-refresco: ON' : 'Auto-refresco: OFF',
            icon: Icon(_forex.autoRefresh ? Icons.sync : Icons.sync_disabled),
            onPressed: () => _forex.setAutoRefresh(!_forex.autoRefresh),
          ),
          ...common,
        ];
      case 1:
        return [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _news.loading ? null : () => _news.load(),
          ),
          ...common,
        ];
      default:
        return [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _forex.load();
              _crypto.load();
            },
          ),
          ...common,
        ];
    }
  }
}
