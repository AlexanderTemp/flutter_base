// Cinta automática de precios: monedas seleccionadas + boliviano. Se muestra arriba
// de "Próximas". Design system AppFlowy.
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../bob/bob_controller.dart';
import '../crypto/crypto_controller.dart';

class PriceBar extends StatefulWidget {
  const PriceBar({super.key, required this.crypto, required this.bob});
  final CryptoController crypto;
  final BobController bob;

  @override
  State<PriceBar> createState() => _PriceBarState();
}

class _PriceBarState extends State<PriceBar>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final Ticker _ticker = createTicker(_advance);
  Duration _lastTick = Duration.zero;
  Duration _pauseUntil = Duration.zero;
  bool _interacting = false;
  bool _autoScroll = true;
  double _direction = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (media.disableAnimations || media.accessibleNavigation) {
      _ticker.stop();
    } else if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _pauseUntil = Duration.zero;
      _ticker.start();
    }
  }

  void _advance(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    if (!_autoScroll ||
        _interacting ||
        elapsed < _pauseUntil ||
        !_scroll.hasClients ||
        !_scroll.position.hasContentDimensions) {
      return;
    }
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    final next = (_scroll.offset + _direction * 28 * seconds.clamp(0, .1))
        .clamp(0.0, max);
    _scroll.jumpTo(next);
    if (next == 0 || next == max) {
      _direction *= -1;
      _pauseUntil = elapsed + const Duration(milliseconds: 1200);
    }
  }

  void _resume() {
    _interacting = false;
    _pauseUntil = _lastTick + const Duration(seconds: 3);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final items = <Widget>[];

    for (final p in widget.crypto.prices) {
      final up = p.change24h >= 0;
      final color = up ? t.textColorScheme.success : t.textColorScheme.error;
      items.add(
        _chip(
          t,
          p.symbol,
          '\$${p.priceFmt}',
          '${up ? "▲" : "▼"}${p.change24h.abs().toStringAsFixed(1)}%',
          color,
        ),
      );
    }
    if (widget.bob.rate != null) {
      items.add(
        _chip(
          t,
          'BOB',
          'Bs ${widget.bob.rate!.value}',
          '/\$us',
          t.textColorScheme.action,
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        Text(
          widget.crypto.loading || widget.bob.loading
              ? 'Cargando precios…'
              : 'Elige tus monedas en Ajustes',
          style: t.textStyle.caption.standard(
            color: t.textColorScheme.tertiary,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        color: t.surfaceColorScheme.layer02,
        border: Border(bottom: BorderSide(color: t.borderColorScheme.primary)),
      ),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              onEnter: (_) => _interacting = true,
              onExit: (_) => _resume(),
              child: Listener(
                onPointerDown: (_) => _interacting = true,
                onPointerUp: (_) => _resume(),
                onPointerCancel: (_) => _resume(),
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (_) {
                    _pauseUntil = _lastTick + const Duration(seconds: 3);
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        for (final w in items) ...[
                          w,
                          const SizedBox(width: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!MediaQuery.of(context).disableAnimations &&
              !MediaQuery.of(context).accessibleNavigation)
            IconButton(
              tooltip: _autoScroll
                  ? 'Pausar cinta de precios'
                  : 'Reanudar cinta de precios',
              icon: Icon(
                _autoScroll ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 20,
              ),
              onPressed: () => setState(() => _autoScroll = !_autoScroll),
            ),
        ],
      ),
    );
  }

  Widget _chip(
    AppFlowyThemeData t,
    String sym,
    String price,
    String chg,
    Color color,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$sym ',
        style: t.textStyle.caption.enhanced(color: t.textColorScheme.primary),
      ),
      Text(
        price,
        style: t.textStyle.caption.standard(color: t.textColorScheme.primary),
      ),
      const SizedBox(width: 4),
      Text(chg, style: t.textStyle.caption.standard(color: color)),
    ],
  );
}
