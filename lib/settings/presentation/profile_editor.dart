import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design_system/workspace_controls.dart';
import '../application/settings_cubit.dart';
import 'settings_widgets.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({super.key});

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final _name = TextEditingController(
      text: context.read<SettingsCubit>().state.profileName);
  late final _bio = TextEditingController(
      text: context.read<SettingsCubit>().state.profileBio);
  late int _color = context.read<SettingsCubit>().state.avatarColor;
  final _nameKey = GlobalKey<AFTextFieldState>();

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    if (!context
        .read<SettingsCubit>()
        .updateProfile(_name.text, _bio.text, _color)) {
      _nameKey.currentState!
          .syncError(errorText: 'Escribe un nombre de entre 1 y 40 caracteres');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil local actualizado')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    Widget label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: theme.textStyle.body
                .enhanced(color: theme.textColorScheme.primary)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
          alignment: Alignment.centerLeft,
          child: ProfileAvatar(
              name: context.watch<SettingsCubit>().state.profileName,
              color: _color,
              size: 72)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (index, label) in const [
          (0, 'Azul'),
          (1, 'Verde'),
          (2, 'Ámbar'),
          (3, 'Violeta')
        ])
          WorkspaceChoice(
              label: label,
              selected: _color == index,
              onTap: () => setState(() => _color = index)),
      ]),
      const SizedBox(height: 24),
      label('Nombre para mostrar'),
      Semantics(
          label: 'Nombre para mostrar',
          child: AFTextField(
              key: _nameKey,
              controller: _name,
              maxLength: 40,
              onChanged: (_) => _nameKey.currentState!.clearError())),
      const SizedBox(height: 20),
      label('Sobre ti'),
      Semantics(
          label: 'Sobre ti',
          child: AFTextField(
              controller: _bio,
              hintText: 'Unas palabras sobre ti…',
              maxLength: 160,
              onSubmitted: (_) => _save())),
      const SizedBox(height: 24),
      Align(
          alignment: Alignment.centerLeft,
          child:
              AFFilledTextButton.primary(text: 'Guardar perfil', onTap: _save)),
    ]);
  }
}
