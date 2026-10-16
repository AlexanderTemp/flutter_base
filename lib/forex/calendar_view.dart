// Pestaña "Próximas": calendario de noticias con filtros (impacto, divisa,
// hoy/semana), agrupado por día. Construido sobre el design system AppFlowy.
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        if (controller.calendarEvents.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CalendarFeedStatus(controller: controller),
          ),
        _filterBar(context, t),
        Divider(height: 1, color: t.borderColorScheme.primary),
        Expanded(child: _body(context, t)),
      ],
    );
  }

  Widget _filterBar(BuildContext context, AppFlowyThemeData t) {
    final c = controller;
    const impactLabels = {'high': 'Alto', 'medium': 'Medio', 'low': 'Bajo'};
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
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
          const SizedBox(width: 12),
          for (final e in impactLabels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(e.value),
                selected: c.impacts.contains(e.key),
                avatar: CircleAvatar(
                  backgroundColor: impactColor(context, e.key),
                  radius: 6,
                ),
                onSelected: (_) => c.toggleImpact(e.key),
              ),
            ),
          if (c.availableCurrencies.isNotEmpty) ...[
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: const Text('Todas'),
                selected: c.currencies.isEmpty,
                onSelected: (_) => c.clearCurrencies(),
              ),
            ),
            for (final cur in c.availableCurrencies)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(cur),
                  selected: c.currencies.contains(cur),
                  onSelected: (_) => c.toggleCurrency(cur),
                ),
              ),
          ],
          if (c.lastUpdated != null) ...[
            const SizedBox(width: 6),
            Text(
              '${c.showingPrevious ? "Guardado" : "Actualizado"} ${_hhmm(c.lastUpdated!)}',
              style: t.textStyle.caption.standard(
                color: t.textColorScheme.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppFlowyThemeData t) {
    final c = controller;
    if (c.loading && c.calendarEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text('Consultando el calendario…'),
            if (c.canShowPrevious)
              TextButton(
                onPressed: c.showPreviousData,
                child: const Text('Mostrar datos anteriores'),
              ),
          ],
        ),
      );
    }
    if (c.error != null && c.calendarEvents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [CalendarFeedStatus(controller: c)],
        ),
      );
    }
    final events = c.events;
    if (events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              c.scope == ForexScope.today
                  ? 'No hay noticias con estos filtros hoy.'
                  : 'No hay noticias con estos filtros esta semana.',
              style: t.textStyle.body.standard(
                color: t.textColorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }
    final rows = _groupByDay(events);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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

  Future<void> _refresh() async {
    await Future.wait([controller.load(), crypto.load(), bob.load()]);
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

class CalendarFeedStatus extends StatelessWidget {
  const CalendarFeedStatus({super.key, required this.controller});
  final ForexController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.error == null && !c.showingPrevious && !c.canShowPrevious) {
      return const SizedBox.shrink();
    }
    final t = AppFlowyTheme.of(context);
    final savedAt = c.lastUpdated;
    final title = c.showingPrevious && savedAt != null
        ? 'Datos anteriores'
        : c.loading
        ? 'Consultando el calendario…'
        : 'Calendario no disponible';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: AfCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpansionTile(
                dense: true,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  title,
                  style: t.textStyle.body.enhanced(
                    color: t.textColorScheme.primary,
                  ),
                ),
                subtitle: c.showingPrevious && savedAt != null
                    ? Text(
                        'Guardados el ${DateFormat('dd/MM/yyyy HH:mm').format(savedAt)}',
                        style: t.textStyle.caption.standard(
                          color: t.textColorScheme.secondary,
                        ),
                      )
                    : const Text('Toca para ver detalles'),
                children: [
                  if (c.error != null)
                    Text(
                      c.error!,
                      style: t.textStyle.caption.standard(
                        color: t.textColorScheme.secondary,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    c.loading
                        ? 'Buscando datos nuevos sin borrar el calendario guardado.'
                        : c.autoRefresh
                        ? 'Se volverá a intentar automáticamente cada 60 segundos.'
                        : 'La actualización automática está desactivada. Puedes reintentar.',
                    style: t.textStyle.caption.standard(
                      color: t.textColorScheme.secondary,
                    ),
                  ),
                  if (!c.canShowPrevious && c.calendarEvents.isEmpty)
                    Text(
                      'Aún no hay una copia guardada. Se creará tras la primera descarga correcta.',
                      style: t.textStyle.caption.standard(
                        color: t.textColorScheme.secondary,
                      ),
                    ),
                  TextButton(
                    onPressed: c.loading ? null : () => c.load(),
                    child: const Text('Reintentar ahora'),
                  ),
                ],
              ),
              if (c.canShowPrevious)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: FilledButton(
                    onPressed: c.showPreviousData,
                    child: const Text('Mostrar datos anteriores'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});
  final DateTime day;

  static const _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    final base =
        '${_days[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';
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
          Text(
            _label(),
            style: t.textStyle.body.enhanced(color: t.textColorScheme.action),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(color: t.borderColorScheme.primary, height: 1),
          ),
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
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Fecha programada · hora local',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(tm),
                  style: t.textStyle.caption.standard(
                    color: t.textColorScheme.tertiary,
                  ),
                ),
                Text(
                  hhmm,
                  style: t.textStyle.heading4.enhanced(
                    color: t.textColorScheme.primary,
                  ),
                ),
              ],
            ),
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
                      fg: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.name,
                        style: t.textStyle.body.standard(
                          color: t.textColorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    AfPill(
                      text: impactLabel(event.impact),
                      bg: color.withValues(alpha: 0.14),
                      fg: color,
                    ),
                    Text(
                      'Forecast ${event.forecast.isEmpty ? "—" : event.forecast}'
                      ' · Previo ${event.previous.isEmpty ? "—" : event.previous}',
                      style: t.textStyle.caption.standard(
                        color: t.textColorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (past)
            Tooltip(
              message: 'Hora programada pasada',
              child: Icon(
                Icons.history,
                size: 18,
                color: t.textColorScheme.tertiary,
              ),
            ),
        ],
      ),
    );
  }
}
