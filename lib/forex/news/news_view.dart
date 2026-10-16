// Noticias: impacto original del calendario de Forex Factory y titulares RSS.
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../calendar_view.dart';
import '../forex_controller.dart';
import '../ui.dart';
import 'news_controller.dart';
import 'news_models.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key, required this.controller, required this.forex});
  final NewsController controller;
  final ForexController forex;

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  bool _economic = true;
  String? _impact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Forex Factory'),
                selected: _economic,
                onSelected: (_) => setState(() => _economic = true),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('Titulares RSS'),
                selected: !_economic,
                onSelected: (_) => setState(() => _economic = false),
              ),
              if (_economic) ...[
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _impact == null,
                  onSelected: (_) => setState(() => _impact = null),
                ),
                for (final impact in ['high', 'medium', 'low', 'holiday'])
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(impactLabel(impact)),
                      avatar: Icon(
                        Icons.circle,
                        size: 10,
                        color: impactColor(context, impact),
                      ),
                      selected: _impact == impact,
                      onSelected: (_) => setState(() => _impact = impact),
                    ),
                  ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _economic
              ? _economicNews()
              : _RssNewsView(controller: widget.controller),
        ),
      ],
    );
  }

  Widget _economicNews() {
    final c = widget.forex;
    final events = c.calendarEvents
        .where((e) => _impact == null || e.impact == _impact)
        .toList();
    if (c.loading && c.calendarEvents.isEmpty && !c.canShowPrevious) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => c.load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        children: [
          CalendarFeedStatus(controller: c),
          const Text(
            'Calendario de Forex Factory · fechas programadas, hora local.',
          ),
          const SizedBox(height: 12),
          if (events.isEmpty && c.error == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay eventos con este nivel de impacto.'),
            ),
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EventTile(event: event),
            ),
        ],
      ),
    );
  }
}

class _RssNewsView extends StatelessWidget {
  const _RssNewsView({required this.controller});
  final NewsController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final c = controller;
    if (c.loading && c.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.error != null && c.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => c.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 40,
                    color: t.textColorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.error!,
                    textAlign: TextAlign.center,
                    style: t.textStyle.body.standard(
                      color: t.textColorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => c.load(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => c.load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        itemCount: c.items.length + (c.error != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (c.error != null && i == 0) {
            return Text(
              'Sin actualizar · desliza para reintentar',
              style: t.textStyle.caption.standard(
                color: t.textColorScheme.secondary,
              ),
            );
          }
          return _NewsTile(item: c.items[i - (c.error != null ? 1 : 0)]);
        },
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    return AfCard(
      onTap: item.link.isEmpty ? null : () => _open(context, item.link),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AfPill(
                text: item.source,
                bg: t.fillColorScheme.infoLight,
                fg: t.textColorScheme.info,
              ),
              AfPill(
                text: 'Sin impacto publicado',
                bg: t.textColorScheme.tertiary.withValues(alpha: 0.06),
                fg: t.textColorScheme.secondary,
              ),
              Text(
                item.published == null
                    ? 'Sin fecha'
                    : DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(item.published!.toLocal()),
                style: t.textStyle.caption.standard(
                  color: t.textColorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: t.textStyle.body.enhanced(color: t.textColorScheme.primary),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textStyle.caption.standard(
                color: t.textColorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    try {
      if (uri != null &&
          const {'https', 'http'}.contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          await launchUrl(uri, mode: LaunchMode.externalApplication))
        return;
    } catch (e) {
      debugPrint('Tradex: no se pudo abrir el enlace: $e');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la noticia.')),
      );
    }
  }
}
