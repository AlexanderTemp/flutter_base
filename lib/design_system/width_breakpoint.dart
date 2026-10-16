import 'package:flutter/widgets.dart';

/// Igual que un `LayoutBuilder` que solo compara el ancho, pero sin reconstruir
/// cuando cambia la altura (p. ej. en cada fotograma de la animación del teclado).
///
/// [builder] se vuelve a ejecutar cuando [wide] cambia, cuando el padre se
/// reconstruye o cuando cambia alguna dependencia heredada que use.
class WidthBreakpoint extends StatelessWidget {
  const WidthBreakpoint({
    super.key,
    required this.breakpoint,
    required this.builder,
  });

  final double breakpoint;
  final Widget Function(BuildContext context, bool wide) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => _CachedBreakpoint(
          wide: constraints.maxWidth >= breakpoint,
          builder: builder,
        ),
      );
}

class _CachedBreakpoint extends StatefulWidget {
  const _CachedBreakpoint({required this.wide, required this.builder});

  final bool wide;
  final Widget Function(BuildContext context, bool wide) builder;

  @override
  State<_CachedBreakpoint> createState() => _CachedBreakpointState();
}

class _CachedBreakpointState extends State<_CachedBreakpoint> {
  Widget? _child;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _child = null;
  }

  @override
  void didUpdateWidget(_CachedBreakpoint oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El builder es un closure nuevo en cada build del padre; si es el mismo,
    // el LayoutBuilder solo cambió de altura y la instancia en caché sigue valiendo.
    if (oldWidget.wide != widget.wide || oldWidget.builder != widget.builder) {
      _child = null;
    }
  }

  // Devolver la misma instancia hace que Flutter omita el subárbol completo.
  @override
  Widget build(BuildContext context) =>
      _child ??= widget.builder(context, widget.wide);
}
