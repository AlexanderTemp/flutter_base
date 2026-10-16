import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// Tarjeta con superficie, borde y radio del design system.
class AfCard extends StatelessWidget {
  const AfCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final content = Padding(padding: padding, child: child);
    // Sin recorte para conservar los anillos de foco de los controles hijos.
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceColorScheme.primary,
        borderRadius: BorderRadius.circular(t.borderRadius.l),
        border: Border.all(color: t.borderColorScheme.primary),
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Píldora pequeña con relleno del tema.
class AfPill extends StatelessWidget {
  const AfPill({super.key, required this.text, this.bg, this.fg});
  final String text;
  final Color? bg;
  final Color? fg;

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg ?? t.fillColorScheme.themeSelect,
        borderRadius: BorderRadius.circular(t.borderRadius.s),
      ),
      child: Text(
        text,
        style:
            t.textStyle.caption.enhanced(color: fg ?? t.textColorScheme.action),
      ),
    );
  }
}
