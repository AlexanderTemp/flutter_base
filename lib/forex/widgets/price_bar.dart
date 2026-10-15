// Barra fija de precios: monedas seleccionadas + boliviano. Se muestra arriba
// de "Próximas". Design system AppFlowy.
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import '../bob/bob_controller.dart';
import '../crypto/crypto_controller.dart';

class PriceBar extends StatelessWidget {
  const PriceBar({super.key, required this.crypto, required this.bob});
  final CryptoController crypto;
  final BobController bob;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final items = <Widget>[];

    for (final p in crypto.prices) {
      final up = p.change24h >= 0;
      final color = up ? t.textColorScheme.success : t.textColorScheme.error;
      items.add(_chip(t, p.symbol, '\$${p.priceFmt}',
          '${up ? "▲" : "▼"}${p.change24h.abs().toStringAsFixed(1)}%', color));
    }
    if (bob.rate != null) {
      items.add(_chip(t, 'BOB', 'Bs ${bob.rate!.value}', '/\$us',
          t.textColorScheme.action));
    }
    if (items.isEmpty) {
      items.add(Text(
        crypto.loading || bob.loading ? 'Cargando precios…' : 'Sin precios',
        style: t.textStyle.caption.standard(color: t.textColorScheme.tertiary),
      ));
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: t.surfaceColorScheme.layer02,
        border: Border(
            bottom: BorderSide(color: t.borderColorScheme.primary)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final w in items) ...[
            Center(child: w),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }

  Widget _chip(AppFlowyThemeData t, String sym, String price, String chg,
          Color color) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$sym ',
              style: t.textStyle.caption.enhanced(color: t.textColorScheme.primary)),
          Text(price,
              style: t.textStyle.caption.standard(color: t.textColorScheme.primary)),
          const SizedBox(width: 4),
          Text(chg, style: t.textStyle.caption.standard(color: color)),
        ],
      );
}
