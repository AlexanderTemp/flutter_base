// Pestaña "Próximas": calendario de noticias con filtros (impacto, divisa,
// hoy/semana), agrupado por día. Construido sobre el design system AppFlowy.
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import 'bob/bob_controller.dart';
import 'crypto/crypto_controller.dart';
import 'ff_models.dart';
import 'forex_controller.dart';
import 'ui.dart';
import 'widgets/price_bar.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({
    super.key,
    required this.controller,
    required this.crypto,
    required this.bob,
  });
  final ForexController controller;
  final CryptoController crypto;
  final BobController bob;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    return Column(
      children: [
        PriceBar(crypto: crypto, bob: bob),
        _filterBar(context, t),
        Divider(height: 1, color: t.borderColorScheme.primary),
        Expanded(child: _body(context, t)),
      ],
    );
  }

  Widget _filterBar(BuildContext context, AppFlowyThemeData t) {
    final c = controller;
    const impactLabels = {'high': 'Alto', 'medium': 'Medio', 'low': 'Bajo'};
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
                    style: t.textStyle.caption
                        .standard(color: t.textColorScheme.tertiary)),
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
                      backgroundColor: impactColor(context, e.key), radius: 6),
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

  Widget _body(BuildContext context, AppFlowyThemeData t) {
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
        child: Text(
          c.scope == ForexScope.today
              ? 'No hay noticias con estos filtros hoy.'
              : 'No hay noticias con estos filtros esta semana.',
          style: t.textStyle.body.standard(color: t.textColorScheme.secondary),
        ),
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
    final t = AppFlowyTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: t.textColorScheme.error, size: 40),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: t.textStyle.body
                    .standard(color: t.textColorScheme.secondary)),
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
    final t = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Row(
        children: [
          Text(_label(),
              style: t.textStyle.body.enhanced(color: t.textColorScheme.action)),
          const SizedBox(width: 10),
          Expanded(
              child: Divider(color: t.borderColorScheme.primary, height: 1)),
        ],
      ),
    );
  }
}

class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event});
  final FfEvent event;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final tm = event.time;
    final hhmm =
        '${tm.hour.toString().padLeft(2, '0')}:${tm.minute.toString().padLeft(2, '0')}';
    final past = tm.isBefore(DateTime.now());
    final color = impactColor(context, event.impact);
    return AfCard(
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
              Text(_dayLabel(tm),
                  style: t.textStyle.caption
                      .standard(color: t.textColorScheme.tertiary)),
              Text(hhmm,
                  style: t.textStyle.heading4
                      .enhanced(color: t.textColorScheme.primary)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AfPill(
                        text: event.currency,
                        bg: color.withValues(alpha: 0.18),
                        fg: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(event.name,
                          style: t.textStyle.body
                              .standard(color: t.textColorScheme.primary),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Forecast ${event.forecast.isEmpty ? "—" : event.forecast}'
                  '   ·   Previo ${event.previous.isEmpty ? "—" : event.previous}',
                  style: t.textStyle.caption
                      .standard(color: t.textColorScheme.secondary),
                ),
              ],
            ),
          ),
          if (past)
            Icon(Icons.check_circle,
                size: 18, color: t.textColorScheme.tertiary),
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return '${days[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}';
  }
}
