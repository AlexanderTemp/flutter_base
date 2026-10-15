// Pantalla principal de la app Forex: noticias fuertes con filtros
// (impacto, divisa, hoy/semana) y auto-refresco en tiempo real.
import 'package:flutter/material.dart';

import 'ff_models.dart';
import 'ff_notifications.dart';
import 'forex_controller.dart';

class ForexHomePage extends StatefulWidget {
  const ForexHomePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<ForexHomePage> createState() => _ForexHomePageState();
}

class _ForexHomePageState extends State<ForexHomePage> {
  final _controller = ForexController();

  @override
  void initState() {
    super.initState();
    FfNotifications.instance.init();
    _controller.addListener(_onChange);
    _controller.start();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = _controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forex · Noticias fuertes'),
        actions: [
          IconButton(
            tooltip: c.autoRefresh ? 'Auto-refresco: ON' : 'Auto-refresco: OFF',
            icon: Icon(c.autoRefresh ? Icons.sync : Icons.sync_disabled),
            onPressed: () => c.setAutoRefresh(!c.autoRefresh),
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
          IconButton(
            tooltip: 'Cambiar tema',
            icon: const Icon(Icons.contrast),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: c.loading ? null : () => c.load(),
          ),
        ],
      ),
      body: Column(
        children: [
          _filterBar(context, cs),
          const Divider(height: 1),
          Expanded(child: _body(context, cs)),
        ],
      ),
    );
  }

  Widget _filterBar(BuildContext context, ColorScheme cs) {
    final c = _controller;
    const impactLabels = {'high': 'Alto', 'medium': 'Medio', 'low': 'Bajo'};
    const impactColors = {
      'high': Colors.red,
      'medium': Colors.orange,
      'low': Colors.amber
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SegmentedButton<ForexScope>(
                style: const ButtonStyle(
                    visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: ForexScope.today, label: Text('Hoy')),
                  ButtonSegment(value: ForexScope.week, label: Text('Semana')),
                ],
                selected: {c.scope},
                onSelectionChanged: (s) => c.setScope(s.first),
              ),
              const Spacer(),
              if (c.lastUpdated != null)
                Text(
                  'Actualizado ${_hhmm(c.lastUpdated!)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Filtro de impacto
          Wrap(
            spacing: 6,
            children: [
              for (final e in impactLabels.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: c.impacts.contains(e.key),
                  avatar: CircleAvatar(
                      backgroundColor: impactColors[e.key], radius: 6),
                  onSelected: (_) => c.toggleImpact(e.key),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Filtro de divisa (dinámico)
          if (c.availableCurrencies.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: c.currencies.isEmpty,
                  onSelected: (_) => c.clearCurrencies(),
                ),
                for (final cur in c.availableCurrencies)
                  FilterChip(
                    label: Text(cur),
                    selected: c.currencies.contains(cur),
                    onSelected: (_) => c.toggleCurrency(cur),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ColorScheme cs) {
    final c = _controller;
    if (c.loading && c.events.isEmpty && c.lastUpdated == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.error != null && c.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: cs.error, size: 40),
              const SizedBox(height: 12),
              Text(c.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: () => c.load(), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final events = c.events;
    if (events.isEmpty) {
      return Center(
        child: Text(c.scope == ForexScope.today
            ? 'No hay noticias con estos filtros hoy.'
            : 'No hay noticias con estos filtros esta semana.'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => c.load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _EventTile(event: events[i]),
      ),
    );
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final FfEvent event;

  static const _impactColor = {
    'high': Colors.red,
    'medium': Colors.orange,
    'low': Colors.amber,
    'holiday': Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = event.time;
    final hhmm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final past = t.isBefore(DateTime.now());
    final color = _impactColor[event.impact] ?? Colors.red;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 42,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dayLabel(t),
                    style: Theme.of(context).textTheme.labelSmall),
                Text(hhmm,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip(context, event.currency, cs.primaryContainer,
                          cs.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(event.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Forecast ${event.forecast.isEmpty ? "—" : event.forecast}'
                    '   ·   Previo ${event.previous.isEmpty ? "—" : event.previous}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (past) Icon(Icons.check_circle, size: 18, color: cs.outline),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String text, Color bg, Color fg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: fg, fontWeight: FontWeight.bold)),
      );

  String _dayLabel(DateTime d) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${days[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}';
  }
}
