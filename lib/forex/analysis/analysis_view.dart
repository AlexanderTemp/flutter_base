// Pestaña "Análisis": precios cripto en vivo + análisis por plantillas de las
// noticias de alto impacto con reacción cripto. Design system AppFlowy.
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../crypto/crypto_client.dart';
import '../calendar_view.dart';
import '../crypto/crypto_controller.dart';
import '../ff_models.dart';
import '../forex_controller.dart';
import '../ui.dart';
import 'impact_analysis.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key, required this.forex, required this.crypto});

  final ForexController forex;
  final CryptoController crypto;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final events = forex.highImpactEvents;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([forex.load(), crypto.load()]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        children: [
          CalendarFeedStatus(controller: forex),
          AfCard(child: _CryptoBar(crypto: crypto)),
          const SizedBox(height: 10),
          _disclaimer(context, t),
          const SizedBox(height: 12),
          Text(
            'Noticias de alto impacto',
            style: t.textStyle.heading4.enhanced(
              color: t.textColorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Sin noticias de alto impacto cargadas.',
                  style: t.textStyle.body.standard(
                    color: t.textColorScheme.secondary,
                  ),
                ),
              ),
            )
          else
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AnalysisCard(event: e),
              ),
            ),
        ],
      ),
    );
  }

  Widget _disclaimer(BuildContext context, AppFlowyThemeData t) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: t.fillColorScheme.warningLight,
      borderRadius: BorderRadius.circular(t.borderRadius.m),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 18, color: t.textColorScheme.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Heurística educativa, no es consejo financiero. '
            'La reacción real del mercado puede variar.',
            style: t.textStyle.caption.standard(
              color: t.textColorScheme.primary,
            ),
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
    final t = AppFlowyTheme.of(context);
    if (crypto.prices.isEmpty) {
      return SizedBox(
        height: 44,
        child: Center(
          child: crypto.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  crypto.error ?? 'Sin datos de cripto',
                  style: t.textStyle.caption.standard(
                    color: t.textColorScheme.secondary,
                  ),
                ),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final price in crypto.prices)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _CryptoTile(price: price),
            ),
        ],
      ),
    );
  }
}

class _CryptoTile extends StatelessWidget {
  const _CryptoTile({required this.price});
  final CryptoPrice price;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final up = price.change24h >= 0;
    final color = up ? t.textColorScheme.success : t.textColorScheme.error;
    return Column(
      children: [
        Text(
          price.symbol,
          style: t.textStyle.caption.enhanced(color: t.textColorScheme.primary),
        ),
        Text(
          '\$${price.priceFmt}',
          style: t.textStyle.body.standard(color: t.textColorScheme.primary),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              up ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              color: color,
              size: 18,
            ),
            Text(
              '${price.change24h.toStringAsFixed(2)}%',
              style: t.textStyle.caption.standard(color: color),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.event});
  final FfEvent event;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final a = ImpactAnalyzer.analyze(event);
    return AfCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: t.textColorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${event.currency} · ${event.name}',
                  style: t.textStyle.body.enhanced(
                    color: t.textColorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Programado · ${DateFormat('dd/MM/yyyy · HH:mm').format(event.time)}',
            style: t.textStyle.caption.standard(
              color: t.textColorScheme.secondary,
            ),
          ),
          _row(
            context,
            t,
            Icons.category_outlined,
            '${a.category}: ${a.measures}',
          ),
          _row(context, t, Icons.trending_up, a.expectation),
          _row(context, t, Icons.currency_bitcoin, a.cryptoReaction),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    AppFlowyThemeData t,
    IconData icon,
    String text,
  ) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: t.textColorScheme.action),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: t.textStyle.caption.standard(
              color: t.textColorScheme.secondary,
            ),
          ),
        ),
      ],
    ),
  );
}
