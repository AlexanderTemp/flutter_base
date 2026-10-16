import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_info.dart';
import '../../design_system/app_logo.dart';
import '../../design_system/components_page.dart';
import '../../design_system/workspace_icon.dart';
import '../../settings/application/settings_cubit.dart';
import '../../settings/presentation/settings_page.dart';
import '../application/workspace_cubit.dart';
import 'new_task_dialog.dart';
import 'workspace_widgets.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => WorkspaceCubit(),
        child: _WorkspaceView(onToggleTheme: onToggleTheme),
      );
}

class _WorkspaceView extends StatefulWidget {
  const _WorkspaceView({required this.onToggleTheme});
  final VoidCallback onToggleTheme;

  @override
  State<_WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends State<_WorkspaceView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  WorkspaceDestination _destination = WorkspaceDestination.tasks;
  // La galería se construye al visitarla por primera vez y luego conserva su estado.
  bool _componentsBuilt = false;
  TaskFilter _filter = TaskFilter.all;
  // Misma instancia mientras `active` no cambie: Flutter omite su subárbol cuando
  // esta página se reconstruye por navegación, filtros o tareas.
  SettingsPage? _settingsPage;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _navigate(WorkspaceDestination destination) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _destination = destination;
      if (destination == WorkspaceDestination.components) _componentsBuilt = true;
      if (destination == WorkspaceDestination.search) _filter = TaskFilter.all;
    });
    if (destination == WorkspaceDestination.search) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  Future<void> _addTask() async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const NewTaskDialog(),
    );
    if (mounted && title != null) {
      context.read<WorkspaceCubit>().addTask(title);
      _searchController.clear();
      setState(() {
        _destination = WorkspaceDestination.tasks;
        _filter = TaskFilter.all;
      });
    }
  }

  SettingsPage _settings() {
    final active = _destination == WorkspaceDestination.settings;
    if (_settingsPage?.active != active) {
      _settingsPage = SettingsPage(active: active);
    }
    return _settingsPage!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    // Solo el dato que muestra la cabecera; editar el perfil no reconstruye esta página.
    final workspaceName =
        context.select((SettingsCubit cubit) => cubit.state.workspaceName);
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      Widget sidebar() => BlocBuilder<WorkspaceCubit, WorkspaceState>(
            builder: (context, state) => WorkspaceSidebar(
              key: const ValueKey('workspace-sidebar'),
              filter: _filter,
              state: state,
              workspaceName: workspaceName,
              destination: _destination,
              onNavigate: (destination) {
                if (!wide) Navigator.of(context).pop();
                _navigate(destination);
              },
              onSelect: (filter) {
                setState(() {
                  _filter = filter;
                  _destination = WorkspaceDestination.tasks;
                });
                if (!wide) Navigator.of(context).pop();
              },
              onCreate: () {
                if (!wide) Navigator.of(context).pop();
                _addTask();
              },
            ),
          );
      return Scaffold(
        key: _scaffoldKey,
        drawer: wide
            ? null
            : Drawer(
                width: 280,
                shape: const RoundedRectangleBorder(),
                child: sidebar()),
        bottomNavigationBar: wide
            ? null
            : WorkspaceBottomNavigation(
                destination: _destination,
                onNavigate: _navigate,
                onCreate: _addTask,
              ),
        body: SafeArea(
          child: Row(children: [
            if (wide) ...[
              SizedBox(width: 248, child: sidebar()),
              VerticalDivider(width: 1, color: theme.borderColorScheme.primary),
            ],
            Expanded(
                child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: theme.borderColorScheme.primary))),
                child: Row(children: [
                  if (!wide)
                    WorkspaceIconButton(
                        label: 'Abrir navegación',
                        icon: Icons.menu,
                        onTap: () => _scaffoldKey.currentState!.openDrawer()),
                  const AppLogo(),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppInfo.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.body
                              .enhanced(color: theme.textColorScheme.primary)),
                      Text('$workspaceName / ${_destination.label}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.caption
                              .standard(color: theme.textColorScheme.secondary)),
                    ],
                  )),
                  IconButton(
                    tooltip: 'Cambiar tema',
                    icon: const Icon(Icons.contrast),
                    onPressed: widget.onToggleTheme,
                  ),
                  IconButton(
                    key: const ValueKey('header-settings'),
                    tooltip: 'Ajustes',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _navigate(WorkspaceDestination.settings),
                  ),
                ]),
              ),
              Expanded(
                child: IndexedStack(
                  index: switch (_destination) {
                    WorkspaceDestination.settings => 1,
                    WorkspaceDestination.components => 2,
                    _ => 0,
                  },
                  children: [
                    TickerMode(
                      enabled: _destination == WorkspaceDestination.tasks ||
                          _destination == WorkspaceDestination.search,
                      child: _TasksPane(
                        wide: wide,
                        filter: _filter,
                        searching: _destination == WorkspaceDestination.search,
                        searchController: _searchController,
                        searchFocus: _searchFocus,
                        onCreate: _addTask,
                      ),
                    ),
                    TickerMode(
                      enabled: _destination == WorkspaceDestination.settings,
                      child: _settings(),
                    ),
                    TickerMode(
                      enabled: _destination == WorkspaceDestination.components,
                      child: _componentsBuilt
                          ? const ComponentsPage()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ])),
          ]),
        ),
      );
    });
  }
}

/// Lista de tareas con búsqueda. Lee tareas y preferencias por sí misma y la
/// búsqueda solo reconstruye la lista filtrada, no la página.
class _TasksPane extends StatelessWidget {
  const _TasksPane({
    required this.wide,
    required this.filter,
    required this.searching,
    required this.searchController,
    required this.searchFocus,
    required this.onCreate,
  });

  final bool wide;
  final TaskFilter filter;
  final bool searching;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final state = context.watch<WorkspaceCubit>().state;
    final (showCompleted, compact) = context.select((SettingsCubit cubit) =>
        (cubit.state.showCompleted, cubit.state.compact));
    final tasks = state.tasks.where((task) {
      final matchesFilter = switch (filter) {
        TaskFilter.all => true,
        TaskFilter.pending => !task.completed,
        TaskFilter.completed => task.completed,
      };
      return matchesFilter &&
          (showCompleted || !task.completed || filter == TaskFilter.completed);
    }).toList();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: wide ? 64 : 20, vertical: wide ? 56 : 28),
              sliver: SliverMainAxisGroup(slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: theme.fillColorScheme.infoLight,
                            borderRadius:
                                BorderRadius.circular(theme.borderRadius.l)),
                        child: WorkspaceIcon('type_page',
                            size: 32, color: theme.textColorScheme.action),
                      ),
                      const SizedBox(height: 24),
                      Text(searching ? 'Buscar' : 'Mis tareas',
                          style: theme.textStyle.heading1
                              .enhanced(color: theme.textColorScheme.primary)),
                      const SizedBox(height: 12),
                      Text(
                          'Un lugar tranquilo para tus ideas y tus próximos pasos.',
                          style: theme.textStyle.title
                              .standard(color: theme.textColorScheme.secondary)),
                      const SizedBox(height: 24),
                      Wrap(spacing: 16, runSpacing: 8, children: [
                        Text(
                            '${state.tasks.length - state.completedCount} pendientes',
                            style: theme.textStyle.body.standard(
                                color: theme.textColorScheme.secondary)),
                        Text('${state.completedCount} completadas',
                            style: theme.textStyle.body.standard(
                                color: theme.textColorScheme.secondary)),
                      ]),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const WorkspaceIcon('type_todo'),
                              const SizedBox(width: 8),
                              Text(filter.label,
                                  style: theme.textStyle.title.enhanced(
                                      color: theme.textColorScheme.primary)),
                            ]),
                            Semantics(
                              button: true,
                              container: true,
                              child: AFFilledTextButton.primary(
                                key: const ValueKey('new-task'),
                                text: 'Nueva tarea',
                                onTap: onCreate,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                          label: 'Buscar tareas',
                          child: AFTextField(
                            key: const ValueKey('search-tasks'),
                            controller: searchController,
                            focusNode: searchFocus,
                            hintText: 'Buscar en esta página…',
                            size: AFTextFieldSize.m,
                            // Solo el icono escucha el texto para alternar lupa/limpiar.
                            suffixIconBuilder: (_, __) =>
                                ValueListenableBuilder<TextEditingValue>(
                              valueListenable: searchController,
                              builder: (_, value, __) => value.text.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child:
                                          WorkspaceIcon('search_icon', size: 18))
                                  : WorkspaceIconButton(
                                      label: 'Limpiar búsqueda',
                                      icon: Icons.close,
                                      onTap: searchController.clear),
                            ),
                          )),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) {
                    final query = _normalizeSearch(value.text.trim());
                    final visible = query.isEmpty
                        ? tasks
                        : [
                            for (final task in tasks)
                              if (_normalizeSearch(task.title).contains(query))
                                task
                          ];
                    return DecoratedSliver(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: theme.borderColorScheme.primary),
                        borderRadius:
                            BorderRadius.circular(theme.borderRadius.m),
                      ),
                      sliver: SliverMainAxisGroup(slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Text('NOMBRE DE LA TAREA',
                                    style: theme.textStyle.caption.enhanced(
                                        color: theme.textColorScheme.secondary)),
                              ),
                              Divider(
                                  height: 1,
                                  color: theme.borderColorScheme.primary),
                              if (visible.isEmpty)
                                Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text('No hay tareas que coincidan.',
                                        style: theme.textStyle.body.standard(
                                            color: theme
                                                .textColorScheme.secondary))),
                            ],
                          ),
                        ),
                        // Perezosa: solo construye las filas visibles.
                        SliverList.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final task = visible[index];
                            return WorkspaceTaskRow(
                              key: ValueKey('task-${task.id}'),
                              task: task,
                              compact: compact,
                              onToggle: () => context
                                  .read<WorkspaceCubit>()
                                  .toggleTask(task.id),
                            );
                          },
                        ),
                      ]),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                        'Demo educativa · Los cambios se mantienen solo durante esta sesión.',
                        style: theme.textStyle.caption
                            .standard(color: theme.textColorScheme.secondary)),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeSearch(String value) => value
    .toLowerCase()
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ü', 'u');
