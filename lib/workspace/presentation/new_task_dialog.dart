import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class NewTaskDialog extends StatefulWidget {
  const NewTaskDialog({super.key});

  @override
  State<NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends State<NewTaskDialog> {
  final _input = TextEditingController();
  final _fieldKey = GlobalKey<AFTextFieldState>();
  final _focus = FocusNode();
  Animation<double>? _routeAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation != null) return;
    // Abrir el teclado durante la transición hace competir ambas animaciones
    // por los mismos fotogramas; se enfoca cuando el diálogo ya está visible.
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
    } else {
      _routeAnimation = animation..addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _requestFocus();
  }

  void _requestFocus() {
    if (mounted) _focus.requestFocus();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _focus.dispose();
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    if (_input.text.trim().isEmpty) {
      _fieldKey.currentState!.syncError(errorText: 'Escribe un título');
      return;
    }
    Navigator.of(context).pop(_input.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return _KeyboardInset(
      child: AFModal(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nueva tarea',
                  style: theme.textStyle.heading4
                      .enhanced(color: theme.textColorScheme.primary)),
              const SizedBox(height: 8),
              Text('Dale un nombre a tu siguiente paso.',
                  style: theme.textStyle.body
                      .standard(color: theme.textColorScheme.secondary)),
              const SizedBox(height: 24),
              Semantics(
                label: 'Título',
                child: AFTextField(
                  key: _fieldKey,
                  controller: _input,
                  focusNode: _focus,
                  hintText: '¿Qué quieres hacer?',
                  maxLength: 120,
                  onChanged: (_) => _fieldKey.currentState!.clearError(),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Semantics(
                      button: true,
                      container: true,
                      child: AFOutlinedTextButton.normal(
                          text: 'Cancelar',
                          onTap: () => Navigator.of(context).pop())),
                  Semantics(
                      button: true,
                      container: true,
                      child: AFFilledTextButton.primary(
                          key: const ValueKey('submit-task'),
                          text: 'Crear',
                          onTap: _submit)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solo este widget depende del teclado: en cada fotograma de su animación se
/// recalcula el margen y el contenido del diálogo (misma instancia) no se reconstruye.
class _KeyboardInset extends StatelessWidget {
  const _KeyboardInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: child,
      );
}
