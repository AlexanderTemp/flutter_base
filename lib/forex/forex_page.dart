// Shell de la app Forex: 3 pestañas (Próximas, Noticias, Análisis) con
// navegación inferior. Dueño de los controladores.
import 'package:flutter/material.dart';

import 'analysis/analysis_view.dart';
import 'calendar_view.dart';
import 'crypto/crypto_controller.dart';
import 'ff_notifications.dart';
import 'forex_controller.dart';
import 'news/news_controller.dart';
import 'news/news_view.dart';

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
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    FfNotifications.instance.init();
    for (final l in [_forex, _news, _crypto]) {
      l.addListener(_onChange);
    }
    _forex.start();
    _news.start();
    _crypto.start();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final l in [_forex, _news, _crypto]) {
      l.removeListener(_onChange);
      l.dispose();
    }
    super.dispose();
  }

  static const _titles = ['Próximas', 'Noticias', 'Análisis'];

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
          CalendarView(controller: _forex),
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
    final theme = IconButton(
      tooltip: 'Cambiar tema',
      icon: const Icon(Icons.contrast),
      onPressed: widget.onToggleTheme,
    );
    switch (_tab) {
      case 0:
        return [
          IconButton(
            tooltip:
                _forex.autoRefresh ? 'Auto-refresco: ON' : 'Auto-refresco: OFF',
            icon: Icon(_forex.autoRefresh ? Icons.sync : Icons.sync_disabled),
            onPressed: () => _forex.setAutoRefresh(!_forex.autoRefresh),
          ),
          IconButton(
            tooltip: 'Probar notificación',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => FfNotifications.instance.show(
              id: 1,
              title: '🔴 Prueba de alerta',
              body: 'Las notificaciones funcionan. Verás un aviso ~5 min '
                  'antes de cada noticia fuerte.',
            ),
          ),
          theme,
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _forex.loading ? null : () => _forex.load(),
          ),
        ];
      case 1:
        return [
          theme,
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: _news.loading ? null : () => _news.load(),
          ),
        ];
      default:
        return [
          theme,
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _forex.load();
              _crypto.load();
            },
          ),
        ];
    }
  }
}
