import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../ui.dart';
import 'bob_client.dart';
import 'bob_controller.dart';

class BobView extends StatefulWidget {
  const BobView({super.key, required this.controller});
  final BobController controller;

  @override
  State<BobView> createState() => _BobViewState();
}

class _BobViewState extends State<BobView> {
  int _limit = 30;
  DateTimeRange? _range;

  Future<void> _pickDates() async {
    final history = widget.controller.rate?.history ?? [];
    if (history.isEmpty) return;
    final range = await showDateRangePicker(
      context: context,
      firstDate: history.last.date,
      lastDate: history.first.date,
      initialDateRange: _range,
      helpText: 'Rango del historial',
      saveText: 'Ver registros',
    );
    if (mounted && range != null) setState(() => _range = range);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final t = AppFlowyTheme.of(context);
    final history = c.rate?.history ?? <BobPoint>[];
    final filtered = history.asMap().entries.where(
      (entry) =>
          _range == null ||
          (!entry.value.date.isBefore(_range!.start) &&
              !entry.value.date.isAfter(_range!.end)),
    );
    final rows =
        (_range != null || _limit == 0 ? filtered : filtered.take(_limit))
            .toList();
    final delta = rows.length < 2
        ? null
        : rows.first.value.cents - rows.last.value.cents;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              for (final limit in [7, 30, 50, 0])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(limit == 0 ? 'Todos' : '$limit registros'),
                    selected: _range == null && _limit == limit,
                    onSelected: (_) => setState(() {
                      _limit = limit;
                      _range = null;
                    }),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(_range == null ? 'Por fechas' : 'Cambiar fechas'),
                onPressed: history.isEmpty ? null : _pickDates,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: c.load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              itemCount: rows.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AfCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'USD/BOB · TCO del BCB',
                                style: t.textStyle.body.enhanced(
                                  color: t.textColorScheme.primary,
                                ),
                              ),
                            ),
                            const Tooltip(
                              message:
                                  'Bolivianos por 1 dólar. Si sube USD/BOB, el dólar sube y el boliviano pierde valor frente a él. El TCO es la mediana ponderada por monto de las compras de dólares publicadas por el BCB.',
                              triggerMode: TooltipTriggerMode.tap,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.info_outline, size: 20),
                              ),
                            ),
                          ],
                        ),
                        if (c.rate != null) ...[
                          Text(
                            'Bs ${c.rate!.value}',
                            style: t.textStyle.heading2.enhanced(
                              color: t.textColorScheme.primary,
                            ),
                          ),
                          Text(
                            c.rate!.date == null
                                ? c.rate!.vigencia
                                : 'Vigente ${DateFormat('dd/MM/yyyy').format(c.rate!.date!)}',
                            style: t.textStyle.caption.standard(
                              color: t.textColorScheme.secondary,
                            ),
                          ),
                        ] else
                          Text(
                            c.loading
                                ? 'Consultando el BCB…'
                                : 'Sin cotización disponible.',
                          ),
                        if (c.showingPrevious)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              c.lastUpdated == null
                                  ? 'Datos anteriores'
                                  : 'Guardado · ${DateFormat('dd/MM/yyyy HH:mm').format(c.lastUpdated!)}',
                              style: t.textStyle.caption.standard(
                                color: t.textColorScheme.secondary,
                              ),
                            ),
                          ),
                        if (c.error != null)
                          Text(
                            c.error!,
                            style: t.textStyle.caption.standard(
                              color: t.textColorScheme.secondary,
                            ),
                          ),
                        if (c.loading)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    ),
                  );
                }
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rows.length} registros${rows.isEmpty ? "" : " · ${DateFormat('dd/MM/yyyy').format(rows.last.value.date)} – ${DateFormat('dd/MM/yyyy').format(rows.first.value.date)}"}',
                          style: t.textStyle.caption.standard(
                            color: t.textColorScheme.secondary,
                          ),
                        ),
                        if (delta != null)
                          Text(
                            'Variación del rango · ${delta > 0 ? "+" : ""}${formatBobCents(delta)} Bs',
                            style: t.textStyle.body.enhanced(
                              color: t.textColorScheme.primary,
                            ),
                          ),
                        if (rows.isEmpty && !c.loading)
                          const Text(
                            'No hay registros disponibles para este rango.',
                          ),
                      ],
                    ),
                  );
                }
                final entry = rows[index - 2];
                final previous = entry.key + 1 < history.length
                    ? history[entry.key + 1]
                    : null;
                final change = previous == null
                    ? null
                    : entry.value.cents - previous.cents;
                final percentage = previous == null
                    ? null
                    : ((entry.value.cents - previous.cents) /
                              previous.cents *
                              100)
                          .toStringAsFixed(2)
                          .replaceAll('.', ',')
                          .replaceAll('-', '−');
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  leading: Tooltip(
                    message: change == null
                        ? 'Sin registro anterior'
                        : change > 0
                        ? 'USD sube · BOB se debilita'
                        : change < 0
                        ? 'USD baja · BOB se fortalece'
                        : 'Sin cambio',
                    child: Icon(
                      change == null || change == 0
                          ? Icons.remove
                          : change > 0
                          ? Icons.north_east
                          : Icons.south_east,
                      color: t.textColorScheme.secondary,
                    ),
                  ),
                  title: Text(
                    DateFormat('dd/MM/yyyy').format(entry.value.date),
                  ),
                  subtitle: Text(
                    change == null
                        ? 'Sin anterior'
                        : '${change > 0 ? "+" : ""}${formatBobCents(change)} Bs · ${change > 0 ? "+" : ""}$percentage %',
                    style: t.textStyle.caption.standard(
                      color: t.textColorScheme.secondary,
                    ),
                  ),
                  trailing: Text(
                    'Bs ${entry.value.value}',
                    style: t.textStyle.body.enhanced(
                      color: t.textColorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
