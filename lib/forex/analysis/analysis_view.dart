// Pestaña "Análisis": precios cripto en vivo + análisis por plantillas de las
// noticias de alto impacto, con su reacción típica en cripto.
import 'package:flutter/material.dart';

import '../crypto/crypto_client.dart';
import '../crypto/crypto_controller.dart';
import '../ff_models.dart';
import '../forex_controller.dart';
import 'impact_analysis.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({
    super.key,
    required this.forex,
    required this.crypto,
  });

  final ForexController forex;
  final CryptoController crypto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final events = forex.highImpactEvents;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([forex.load(), crypto.load()]);
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _CryptoBar(crypto: crypto),
          const SizedBox(height: 10),
          _disclaimer(context, cs),
          const SizedBox(height: 12),
          Text('Noticias de alto impacto',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Sin noticias de alto impacto cargadas.')),
            )
          else
            ...events.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnalysisCard(event: e),
                )),
        ],
      ),
    );
  }

  Widget _disclaimer(BuildContext context, ColorScheme cs) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: cs.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Heurística educativa, no es consejo financiero. '
                'La reacción real del mercado puede variar.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
}

class _CryptoBar extends StatelessWidget {
  const _CryptoBar({required this.crypto});
  final CryptoController crypto;

  @override
  Widget build(BuildContext context) {
    if (crypto.prices.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: crypto.loading
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(crypto.error ?? 'Sin datos de cripto'),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: crypto.prices.map((p) => _CryptoTile(price: p)).toList(),
    );
  }
}

class _CryptoTile extends StatelessWidget {
  const _CryptoTile({required this.price});
  final CryptoPrice price;

  @override
  Widget build(BuildContext context) {
    final up = price.change24h >= 0;
    final color = up ? Colors.green : Colors.red;
    return Column(
      children: [
        Text(price.symbol,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text('\$${_fmt(price.usd)}',
            style: Theme.of(context).textTheme.titleMedium),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: color, size: 18),
            Text('${price.change24h.toStringAsFixed(2)}%',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: color)),
          ],
        ),
      ],
    );
  }

  String _fmt(double v) => v >= 1000
      ? v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')
      : v.toStringAsFixed(2);
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.event});
  final FfEvent event;

  @override
  Widget build(BuildContext context) {
    final a = ImpactAnalyzer.analyze(event);
    final hhmm =
        '${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text('${event.currency} · ${event.name}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(hhmm, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            _row(context, Icons.category_outlined, '${a.category}: ${a.measures}'),
            _row(context, Icons.trending_up, a.expectation),
            _row(context, Icons.currency_bitcoin, a.cryptoReaction),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      );
}
