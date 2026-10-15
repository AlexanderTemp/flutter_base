// Pestaña "Próximas": calendario de noticias con filtros (impacto, divisa,
// hoy/semana).
import 'package:flutter/material.dart';

import 'ff_models.dart';
import 'forex_controller.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key, required this.controller});
  final ForexController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _filterBar(context, cs),
        const Divider(height: 1),
        Expanded(child: _body(context, cs)),
      ],
    );
  }

  Widget _filterBar(BuildContext context, ColorScheme cs) {
    final c = controller;
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
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: ForexScope.today, label: Text('Hoy')),
                  ButtonSegment(value: ForexScope.week, label: Text('Semana')),
                ],
                selected: {c.scope},
                onSelectionChanged: (s) => c.setScope(s.first),
              ),
              const Spacer(),
              if (c.lastUpdated != null)
                Text('Actualizado ${_hhmm(c.lastUpdated!)}',
                    style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
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
    final c = controller;
    if (c.loading && c.events.isEmpty && c.lastUpdated == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.error != null && c.events.isEmpty) {
      return _ErrorBox(message: c.error!, onRetry: () => c.load());
    }
    final events = c.events;
    if (events.isEmpty) {
      return Center(
        child: Text(c.scope == ForexScope.today
            ? 'No hay noticias con estos filtros hoy.'
            : 'No hay noticias con estos filtros esta semana.'),
      );
    }
    final rows = _groupByDay(events);
    return RefreshIndicator(
      onRefresh: () => c.load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
        itemCount: rows.length,
        itemBuilder: (_, i) {
          final row = rows[i];
          if (row is DateTime) return _DayHeader(day: row);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: EventTile(event: row as FfEvent),
          );
        },
      ),
    );
  }

  /// Mezcla cabeceras de día (DateTime) con los eventos (FfEvent).
  static List<Object> _groupByDay(List<FfEvent> events) {
    final rows = <Object>[];
    DateTime? last;
    for (final e in events) {
      final day = DateTime(e.time.year, e.time.month, e.time.day);
      if (last == null || day != last) {
        rows.add(day);
        last = day;
      }
      rows.add(e);
    }
    return rows;
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: cs.error, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});
  final DateTime day;

  static const _days = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];
  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    final base = '${_days[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';
    if (diff == 0) return 'Hoy · $base';
    if (diff == 1) return 'Mañana · $base';
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Row(
        children: [
          Text(_label(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.primary, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: cs.outlineVariant, height: 1)),
        ],
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event});
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
