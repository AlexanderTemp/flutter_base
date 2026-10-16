import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// Una misma interacción y estado seleccionado para navegación y preferencias.
class WorkspaceChoice extends StatelessWidget {
  const WorkspaceChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.vertical = false,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool vertical;

  /// Ocupa todo el ancho con el contenido alineado al inicio (listas de
  /// navegación). Sin él se ajusta al contenido, para filas de opciones en `Wrap`.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final color = selected
        ? theme.textColorScheme.action
        : theme.textColorScheme.secondary;
    final children = <Widget>[
      if (icon != null) Icon(icon, size: 22, color: color),
      if (icon != null)
        SizedBox(width: vertical ? 0 : 10, height: vertical ? 4 : 0),
      Flexible(
        child: Text(label,
            textAlign: vertical ? TextAlign.center : TextAlign.start,
            style: theme.textStyle.caption.enhanced(color: color)),
      ),
    ];
    return Semantics(
      button: true,
      container: true,
      selected: selected,
      child: AFBaseButton(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        borderRadius: theme.borderRadius.m,
        borderColor: (_, __, ___, ____) => Colors.transparent,
        backgroundColor: (_, hover, __) => selected
            ? theme.fillColorScheme.themeSelect
            : hover
                ? theme.fillColorScheme.contentHover
                : Colors.transparent,
        builder: (_, __, ___) => vertical
            ? Column(mainAxisSize: MainAxisSize.min, children: children)
            : Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                children: children),
      ),
    );
  }
}

class WorkspaceToggle extends StatelessWidget {
  const WorkspaceToggle({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Semantics(
      label: label,
      value: description,
      toggled: value,
      onTap: () => onChanged(!value),
      excludeSemantics: true,
      child: AFBaseButton(
        onTap: () => onChanged(!value),
        padding: const EdgeInsets.all(16),
        borderRadius: theme.borderRadius.m,
        borderColor: (_, __, ___, ____) => theme.borderColorScheme.primary,
        backgroundColor: (_, hover, __) =>
            hover ? theme.fillColorScheme.contentHover : Colors.transparent,
        builder: (_, __, ___) => Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textStyle.body
                        .enhanced(color: theme.textColorScheme.primary)),
                const SizedBox(height: 4),
                Text(description,
                    style: theme.textStyle.caption
                        .standard(color: theme.textColorScheme.secondary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          AnimatedContainer(
            // Accesos por aspecto: MediaQuery.of también reconstruiría con cada
            // fotograma de la animación del teclado.
            duration: MediaQuery.disableAnimationsOf(context) ||
                    MediaQuery.accessibleNavigationOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            width: 40,
            height: 24,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value
                  ? theme.fillColorScheme.themeThick
                  : theme.iconColorScheme.tertiary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                  color: theme.textColorScheme.onFill, shape: BoxShape.circle),
            ),
          ),
        ]),
      ),
    );
  }
}
