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

  @override
  void dispose() {
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                  hintText: '¿Qué quieres hacer?',
                  autoFocus: true,
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
