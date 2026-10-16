// Bloques de UI construidos sobre el design system AppFlowy (nada de Material
// vanilla): tarjetas, chips y colores de impacto con los tokens del tema.
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surfaceColorScheme.primary,
        borderRadius: BorderRadius.circular(t.borderRadius.l),
        border: Border.all(color: t.borderColorScheme.primary),
      ),
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Píldora pequeña (divisa, fuente…) con relleno del tema.
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
        style: t.textStyle.caption.enhanced(
            color: fg ?? t.textColorScheme.action),
      ),
    );
  }
}

/// Clasificación publicada por el calendario de Forex Factory.
String impactLabel(String impact) => switch (impact) {
  'high' => 'Alto impacto',
  'medium' => 'Impacto medio',
  'low' => 'Bajo impacto',
  'holiday' => 'Festivo',
  _ => 'Sin impacto publicado',
};

/// Rojo/naranja/amarillo, con contraste para cada tema.
Color impactColor(BuildContext context, String impact) {
  final t = AppFlowyTheme.of(context);
  switch (impact) {
    case 'high':
      return Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFF9BA8) : const Color(0xFFB3261E);
    case 'medium':
      return Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFFB36B) : const Color(0xFFA84600);
    case 'low':
      return Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFFFD95C) : const Color(0xFF806000);
    default:
      return t.textColorScheme.tertiary;
  }
}
