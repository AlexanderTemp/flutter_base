// Pestaña "Noticias": últimas noticias forex (RSS). Design system AppFlowy.
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui.dart';
import 'news_controller.dart';
import 'news_models.dart';

class NewsView extends StatelessWidget {
  const NewsView({super.key, required this.controller});
  final NewsController controller;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final c = controller;
    if (c.loading && c.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.error != null && c.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 40, color: t.textColorScheme.error),
              const SizedBox(height: 12),
              Text(c.error!,
                  textAlign: TextAlign.center,
                  style: t.textStyle.body
                      .standard(color: t.textColorScheme.secondary)),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: () => c.load(), child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => c.load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: c.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _NewsTile(item: c.items[i]),
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
          Row(
            children: [
              AfPill(
                text: item.source,
                bg: t.fillColorScheme.infoLight,
                fg: t.textColorScheme.info,
              ),
              const Spacer(),
              if (item.published != null)
                Text(_ago(item.published!),
                    style: t.textStyle.caption
                        .standard(color: t.textColorScheme.tertiary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.title,
              style: t.textStyle.body.enhanced(color: t.textColorScheme.primary)),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.textStyle.caption
                    .standard(color: t.textColorScheme.secondary)),
          ],
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la noticia.')));
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} d';
  }
}
