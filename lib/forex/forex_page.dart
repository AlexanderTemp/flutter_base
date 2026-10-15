// Pantalla de noticias rojas de Forex Factory (fase 1).
// Lista la programación del día/semana desde el feed y programa pre-avisos.
import 'package:flutter/material.dart';

import 'ff_models.dart';
import 'ff_notifications.dart';
import 'forex_controller.dart';

class ForexPage extends StatefulWidget {
  const ForexPage({super.key});

  @override
  State<ForexPage> createState() => _ForexPageState();
}

class _ForexPageState extends State<ForexPage> {
  final _controller = ForexController();

  @override
  void initState() {
    super.initState();
    FfNotifications.instance.init();
    _controller.addListener(_onChange);
    _controller.load();
  }

  void _onChange() => setState(() {});

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
        title: const Text('Noticias rojas · Forex Factory'),
        actions: [
          IconButton(
            tooltip: 'Probar notificación',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => FfNotifications.instance.show(
              id: 1,
              title: '🔴 Prueba de alerta',
              body: 'Las notificaciones funcionan. Verás un aviso ~5 min '
                  'antes de cada noticia de alto impacto.',
            ),
          ),
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: c.loading ? null : c.load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<ForexScope>(
              segments: const [
                ButtonSegment(value: ForexScope.today, label: Text('Hoy')),
                ButtonSegment(value: ForexScope.week, label: Text('Semana')),
              ],
              selected: {c.scope},
              onSelectionChanged: (s) => c.setScope(s.first),
            ),
          ),
          Expanded(child: _body(context, cs)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, ColorScheme cs) {
    final c = _controller;
    if (c.loading && c.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.error != null) {
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
              FilledButton(onPressed: c.load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    final events = c.events;
    if (events.isEmpty) {
      return Center(
        child: Text(c.scope == ForexScope.today
            ? 'No hay noticias rojas hoy.'
            : 'No hay noticias rojas esta semana.'),
      );
    }
    return RefreshIndicator(
      onRefresh: c.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _EventTile(event: events[i]),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final FfEvent event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = event.time;
    final hhmm =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final past = t.isBefore(DateTime.now());
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
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
            if (past)
              Icon(Icons.check_circle, size: 18, color: cs.outline),
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
