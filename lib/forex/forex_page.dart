// Shell de Tradex: Próximas, Noticias, Análisis, Boliviano, Guía y ajustes.
import 'package:flutter/material.dart';

import 'analysis/analysis_view.dart';
import 'bob/bob_controller.dart';
import 'bob/bob_view.dart';
import 'calendar_view.dart';
import 'crypto/crypto_controller.dart';
import 'ff_notifications.dart';
import 'forex_controller.dart';
import 'guide/guide_view.dart';
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _forex.start(),
        _news.start(),
        _crypto.start(),
        _bob.start(),
      ]);
    } catch (e) {
      debugPrint('Tradex: carga inicial incompleta: $e');
    }
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

  static const _titles = [
    'Próximas',
    'Noticias',
    'Análisis',
    'Boliviano',
    'Guía',
  ];

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          onCoinsChanged: () => _crypto.reloadSelection(),
          onNotificationsChanged: _forex.refreshAlerts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/tradex.png',
                width: 36,
                height: 36,
                semanticLabel: 'Tradex',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_titles[_tab], overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: _actions(),
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          TickerMode(
            enabled: _tab == 0,
            child: CalendarView(controller: _forex, crypto: _crypto, bob: _bob),
          ),
          NewsView(controller: _news, forex: _forex),
          AnalysisView(forex: _forex, crypto: _crypto),
          BobView(controller: _bob),
          const GuideView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Próximas',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Noticias',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Análisis',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Boliviano',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Guía',
          ),
        ],
      ),
    );
  }

  List<Widget> _actions() {
    return [
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
  }
}
