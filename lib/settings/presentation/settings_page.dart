import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design_system/workspace_controls.dart';
import '../../auth/application/auth_cubit.dart';
import '../../auth/presentation/sign_in_page.dart';
import '../../workspace/presentation/workspace_widgets.dart';
import '../application/settings_cubit.dart';
import 'profile_editor.dart';
import 'settings_widgets.dart';

enum SettingsSection {
  profile('Mi perfil', Icons.person_outline),
  appearance('Apariencia', Icons.palette_outlined),
  workspace('Espacio de trabajo', Icons.workspaces_outline),
  help('Ayuda y teclado', Icons.help_outline),
  about('Acerca de', Icons.info_outline);

  const SettingsSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.active = true});
  final bool active;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsSection? _section;
  late final TextEditingController _profileName;
  late final TextEditingController _profileBio;
  late int _avatarColor;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state;
    _profileName = TextEditingController(text: settings.profileName);
    _profileBio = TextEditingController(text: settings.profileBio);
    _avatarColor = settings.avatarColor;
  }

  @override
  void dispose() {
    _profileName.dispose();
    _profileBio.dispose();
    super.dispose();
  }

  void _select(SettingsSection? section) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _section = section);
  }

  void _signIn() => Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true, builder: (_) => const SignInPage()));

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final auth = context.watch<AuthCubit>().state;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final section = _section ?? SettingsSection.profile;
      Widget tile(SettingsSection item, String subtitle) => SettingsTile(
          key: ValueKey('settings-${item.name}'),
          title: item.label,
          subtitle: subtitle,
          icon: item.icon,
          selected: wide && section == item,
          onTap: () => _select(item));
      final overview = ListView(
          key: const PageStorageKey('settings-overview'),
          padding: const EdgeInsets.all(20),
          children: [
            Text('Ajustes',
                style: theme.textStyle.heading2
                    .enhanced(color: theme.textColorScheme.primary)),
            const SizedBox(height: 8),
            Text('Un espacio que se siente tuyo.',
                style: theme.textStyle.body
                    .standard(color: theme.textColorScheme.secondary)),
            const SizedBox(height: 24),
            SettingsProfileCard(
                key: const ValueKey('settings-profile'),
                settings: settings,
                subtitle:
                    auth.user?.email ?? 'Perfil local · Editar información',
                onTap: () => _select(SettingsSection.profile)),
            SettingsGroup(title: 'Cuenta', children: [
              SettingsTile(
                  key: const ValueKey('account-entry'),
                  title: auth.user == null
                      ? 'Iniciar sesión'
                      : 'Sesión de demostración',
                  subtitle:
                      auth.user?.email ?? 'Prueba el acceso de demostración',
                  icon: Icons.login,
                  onTap: auth.user == null
                      ? _signIn
                      : () => _select(SettingsSection.profile)),
            ]),
            SettingsGroup(title: 'Personalización', children: [
              tile(SettingsSection.appearance, 'Tema, texto y presentación'),
            ]),
            SettingsGroup(title: 'Espacio de trabajo', children: [
              tile(SettingsSection.workspace, settings.workspaceName),
            ]),
            SettingsGroup(title: 'Ayuda e información', children: [
              tile(SettingsSection.help, 'Navegación y accesibilidad'),
              tile(SettingsSection.about, 'Versión, licencia y preferencias'),
            ]),
            const SizedBox(height: 28),
            Text(
                'Base Flutter · 1.0.0+1\nDatos y perfil locales de esta sesión',
                textAlign: TextAlign.center,
                style: theme.textStyle.caption
                    .standard(color: theme.textColorScheme.secondary)),
          ]);
      final content = ListView(
        key: PageStorageKey(section),
        padding: EdgeInsets.all(wide ? 32 : 20),
        children: [
          Text(section.label,
              style: theme.textStyle.heading3
                  .enhanced(color: theme.textColorScheme.primary)),
          const SizedBox(height: 8),
          Text('Personaliza tu espacio, a tu manera.',
              style: theme.textStyle.body
                  .standard(color: theme.textColorScheme.secondary)),
          const SizedBox(height: 32),
          ...switch (section) {
            SettingsSection.profile => [
                ProfileEditor(
                  nameController: _profileName,
                  bioController: _profileBio,
                  color: _avatarColor,
                  onColorChanged: (color) =>
                      setState(() => _avatarColor = color),
                ),
                SettingsGroup(title: 'Sesión', children: [
                  SettingsTile(
                      key: const ValueKey('profile-session'),
                      title: auth.user == null
                          ? 'Iniciar sesión'
                          : 'Cerrar sesión demo',
                      subtitle: auth.busy
                          ? 'Procesando…'
                          : auth.user?.email ?? 'Continúas como invitado',
                      icon: auth.user == null ? Icons.login : Icons.logout,
                      onTap: auth.user == null
                          ? _signIn
                          : () => context.read<AuthCubit>().signOut()),
                ]),
                if (auth.error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(
                          liveRegion: true,
                          child: Text(auth.error!,
                              style: theme.textStyle.body.standard(
                                  color: theme.textColorScheme.error)))),
                const SizedBox(height: 16),
                const _SettingsHeading(
                    title: 'Perfil local',
                    description:
                        'Tu nombre y avatar se editan en este dispositivo durante la sesión. '
                        'El acceso demo no sincroniza estos datos.'),
              ],
            SettingsSection.appearance => _appearance(context, settings),
            SettingsSection.workspace => [
                const _SettingsHeading(
                    title: 'Nombre del espacio',
                    description: 'Se muestra en la navegación y la cabecera.'),
                _WorkspaceNameEditor(key: ValueKey(settings.workspaceName)),
                const SizedBox(height: 24),
                const _SettingsHeading(
                    title: 'Datos locales',
                    description:
                        'Las tareas y las preferencias viven en memoria. '
                        'Se restablecen al cerrar la aplicación. '
                        'El acceso de demostración no sincroniza datos.'),
              ],
            SettingsSection.help => [
                const _SettingsHeading(
                    title: 'Muévete con el teclado',
                    description:
                        'Tab y Mayús + Tab recorren los controles. Enter activa el botón '
                        'enfocado o envía un campo con acción de envío.'),
                const SizedBox(height: 24),
                const _SettingsHeading(
                    title: 'Encuentra tus tareas',
                    description:
                        'Buscar enfoca el campo de búsqueda. El menú lateral permite '
                        'consultar Todas, Pendientes y Completadas.'),
                const SizedBox(height: 24),
                const _SettingsHeading(
                    title: 'Hazlo más legible',
                    description:
                        'En Apariencia puedes ampliar el texto y elegir el tema. '
                        'La ampliación del sistema operativo también se respeta.'),
              ],
            SettingsSection.about => [
                const _SettingsHeading(
                    title: 'Base Flutter · Fase 2',
                    description:
                        'Versión 1.0.0+1 · Proyecto educativo con Flutter, '
                        'Cubit y el sistema visual de AppFlowy.'),
                const SizedBox(height: 24),
                const _SettingsHeading(
                    title: 'Cómo está construido',
                    description:
                        'Los controles combinan tokens, AFBaseButton, foco, '
                        'teclado y semántica. SettingsCubit mantiene las '
                        'preferencias separado de WorkspaceCubit y sus tareas.'),
                const SizedBox(height: 24),
                const _SettingsHeading(
                    title: 'Código y licencia',
                    description:
                        'Componentes e iconos de AppFlowy bajo AGPLv3. '
                        'Consulta THIRD_PARTY.md y LICENSE en el proyecto.'),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AFOutlinedTextButton.normal(
                    text: 'Restablecer preferencias',
                    onTap: context.read<SettingsCubit>().reset,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Restaura el diseño y el nombre; conserva tus tareas.',
                    style: theme.textStyle.caption
                        .standard(color: theme.textColorScheme.secondary)),
              ],
          },
          const SizedBox(height: 24),
        ],
      );
      final detail =
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!wide)
          Align(
              alignment: Alignment.centerLeft,
              child: WorkspaceIconButton(
                  key: const ValueKey('settings-back'),
                  label: 'Volver a ajustes',
                  icon: Icons.arrow_back,
                  onTap: () => _select(null))),
        Expanded(child: content),
      ]);
      return PopScope(
          canPop: !widget.active || wide || _section == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && widget.active && !wide) _select(null);
          },
          child: wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(
                    width: 256,
                    child:
                        ListView(padding: const EdgeInsets.all(16), children: [
                      SettingsProfileCard(
                          settings: settings,
                          subtitle: auth.user?.email ?? 'Perfil local',
                          onTap: () => _select(SettingsSection.profile)),
                      SettingsGroup(title: 'Tu cuenta', children: [
                        tile(SettingsSection.profile, 'Perfil y sesión')
                      ]),
                      SettingsGroup(title: 'Preferencias', children: [
                        tile(SettingsSection.appearance, 'Tema y presentación'),
                        tile(SettingsSection.workspace,
                            'Nombre y datos locales'),
                      ]),
                      SettingsGroup(title: 'Información', children: [
                        tile(
                            SettingsSection.help, 'Navegación y accesibilidad'),
                        tile(SettingsSection.about, 'Acerca de la base'),
                      ]),
                    ]),
                  ),
                  VerticalDivider(
                      width: 1, color: theme.borderColorScheme.primary),
                  Expanded(child: detail),
                ])
              : (_section == null
                  ? ColoredBox(
                      color: theme.surfaceContainerColorScheme.layer01,
                      child: overview)
                  : detail));
    });
  }

  List<Widget> _appearance(BuildContext context, SettingsState settings) {
    final cubit = context.read<SettingsCubit>();
    return [
      const _SettingsHeading(
          title: 'Tema', description: 'Elige un aspecto o sigue al sistema.'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final mode in ThemeMode.values)
          WorkspaceChoice(
            key: ValueKey('theme-${mode.name}'),
            label: switch (mode) {
              ThemeMode.system => 'Sistema',
              ThemeMode.light => 'Claro',
              ThemeMode.dark => 'Oscuro',
            },
            icon: switch (mode) {
              ThemeMode.system => Icons.brightness_auto_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
            },
            selected: settings.themeMode == mode,
            onTap: () => cubit.setTheme(mode),
          ),
      ]),
      const SizedBox(height: 28),
      const _SettingsHeading(
          title: 'Tamaño de texto',
          description: 'Se combina con la ampliación del sistema operativo.'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (scale, label) in const [
          (1.0, 'Normal'),
          (1.15, 'Grande'),
          (1.3, 'Muy grande'),
        ])
          WorkspaceChoice(
            key: ValueKey('text-scale-$scale'),
            label: label,
            selected: settings.textScale == scale,
            onTap: () => cubit.setTextScale(scale),
          ),
      ]),
      const SizedBox(height: 28),
      WorkspaceToggle(
        key: const ValueKey('compact-toggle'),
        label: 'Filas compactas',
        description: 'Reduce el espacio vertical de la lista de tareas.',
        value: settings.compact,
        onChanged: cubit.setCompact,
      ),
      const SizedBox(height: 12),
      WorkspaceToggle(
        key: const ValueKey('completed-toggle'),
        label: 'Mostrar completadas',
        description: 'Incluye las tareas terminadas en Todas y Buscar. '
            'Siempre puedes consultarlas en Completadas.',
        value: settings.showCompleted,
        onChanged: cubit.setShowCompleted,
      ),
    ];
  }
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: theme.textStyle.body
                .enhanced(color: theme.textColorScheme.primary)),
        const SizedBox(height: 6),
        Text(description,
            style: theme.textStyle.caption
                .standard(color: theme.textColorScheme.secondary)),
      ]),
    );
  }
}

class _WorkspaceNameEditor extends StatefulWidget {
  const _WorkspaceNameEditor({super.key});

  @override
  State<_WorkspaceNameEditor> createState() => _WorkspaceNameEditorState();
}

class _WorkspaceNameEditorState extends State<_WorkspaceNameEditor> {
  late final _controller = TextEditingController(
      text: context.read<SettingsCubit>().state.workspaceName);
  final _fieldKey = GlobalKey<AFTextFieldState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!context.read<SettingsCubit>().renameWorkspace(_controller.text)) {
      _fieldKey.currentState!
          .syncError(errorText: 'Escribe un nombre de entre 1 y 40 caracteres');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Nombre del espacio',
            child: AFTextField(
              key: _fieldKey,
              controller: _controller,
              maxLength: 40,
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: AFFilledTextButton.primary(
                text: 'Guardar nombre', onTap: _save),
          ),
        ],
      );
}
