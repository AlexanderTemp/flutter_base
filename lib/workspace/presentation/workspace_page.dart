import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design_system/workspace_icon.dart';
import '../../forex/forex_page.dart';
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
  TaskFilter _filter = TaskFilter.all;
  String _query = '';

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
        _query = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final settings = context.watch<SettingsCubit>().state;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900;
      return BlocBuilder<WorkspaceCubit, WorkspaceState>(
          builder: (context, state) {
        Widget sidebar() => WorkspaceSidebar(
              key: const ValueKey('workspace-sidebar'),
              filter: _filter,
              state: state,
              workspaceName: settings.workspaceName,
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
                VerticalDivider(
                    width: 1, color: theme.borderColorScheme.primary),
              ],
              Expanded(
                  child: Column(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: theme.borderColorScheme.primary))),
                  child: Row(children: [
                    if (!wide)
                      WorkspaceIconButton(
                          label: 'Abrir navegación',
                          icon: Icons.menu,
                          onTap: () => _scaffoldKey.currentState!.openDrawer()),
                    const WorkspaceIcon('type_page', size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            '${settings.workspaceName} / ${_destination.label}',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textStyle.caption.standard(
                                color: theme.textColorScheme.secondary))),
                    WorkspaceIconButton(
                        label: 'Noticias Forex',
                        icon: Icons.trending_up,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const ForexPage()))),
                    WorkspaceIconButton(
                        label: 'Cambiar tema',
                        icon: Icons.contrast,
                        onTap: widget.onToggleTheme),
                  ]),
                ),
                Expanded(
                  child: IndexedStack(
                    index:
                        _destination == WorkspaceDestination.settings ? 1 : 0,
                    children: [
                      _content(context, state, wide, settings),
                      SettingsPage(
                          active:
                              _destination == WorkspaceDestination.settings),
                    ],
                  ),
                ),
              ])),
            ]),
          ),
        );
      });
    });
  }

  Widget _content(BuildContext context, WorkspaceState state, bool wide,
      SettingsState settings) {
    final theme = AppFlowyTheme.of(context);
    final tasks = state.tasks.where((task) {
      final matchesFilter = switch (_filter) {
        TaskFilter.all => true,
        TaskFilter.pending => !task.completed,
        TaskFilter.completed => task.completed,
      };
      final visible = settings.showCompleted ||
          !task.completed ||
          _filter == TaskFilter.completed;
      return matchesFilter &&
          visible &&
          task.title.toLowerCase().contains(_query);
    }).toList();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: EdgeInsets.symmetric(
              horizontal: wide ? 64 : 20, vertical: wide ? 56 : 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: theme.fillColorScheme.infoLight,
                    borderRadius: BorderRadius.circular(theme.borderRadius.l)),
                child: WorkspaceIcon('type_page',
                    size: 32, color: theme.textColorScheme.action),
              ),
            ),
            const SizedBox(height: 24),
            Text(
                _destination == WorkspaceDestination.search
                    ? 'Buscar'
                    : 'Mis tareas',
                style: theme.textStyle.heading1
                    .enhanced(color: theme.textColorScheme.primary)),
            const SizedBox(height: 12),
            Text('Un lugar tranquilo para tus ideas y tus próximos pasos.',
                style: theme.textStyle.title
                    .standard(color: theme.textColorScheme.secondary)),
            const SizedBox(height: 24),
            Wrap(spacing: 16, runSpacing: 8, children: [
              Text('${state.tasks.length - state.completedCount} pendientes',
                  style: theme.textStyle.body
                      .standard(color: theme.textColorScheme.secondary)),
              Text('${state.completedCount} completadas',
                  style: theme.textStyle.body
                      .standard(color: theme.textColorScheme.secondary)),
            ]),
            const SizedBox(height: 36),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const WorkspaceIcon('type_todo'),
                  const SizedBox(width: 8),
                  Text(_filter.label,
                      style: theme.textStyle.title
                          .enhanced(color: theme.textColorScheme.primary)),
                ]),
                Semantics(
                  button: true,
                  container: true,
                  child: AFFilledTextButton.primary(
                    key: const ValueKey('new-task'),
                    text: 'Nueva tarea',
                    onTap: _addTask,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Semantics(
                label: 'Buscar tareas',
                child: AFTextField(
                  key: const ValueKey('search-tasks'),
                  controller: _searchController,
                  focusNode: _searchFocus,
                  hintText: 'Buscar en esta página…',
                  size: AFTextFieldSize.m,
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  suffixIconBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.all(8),
                      child: WorkspaceIcon('search_icon', size: 18)),
                )),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: theme.borderColorScheme.primary),
                borderRadius: BorderRadius.circular(theme.borderRadius.m),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Text('NOMBRE DE LA TAREA',
                        style: theme.textStyle.caption
                            .enhanced(color: theme.textColorScheme.secondary)),
                  ),
                  Divider(height: 1, color: theme.borderColorScheme.primary),
                  if (tasks.isEmpty)
                    Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No hay tareas que coincidan.',
                            style: theme.textStyle.body.standard(
                                color: theme.textColorScheme.secondary))),
                  for (final task in tasks)
                    WorkspaceTaskRow(
                      key: ValueKey('task-${task.id}'),
                      task: task,
                      compact: settings.compact,
                      onToggle: () =>
                          context.read<WorkspaceCubit>().toggleTask(task.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
                'Demo educativa · Los cambios se mantienen solo durante esta sesión.',
                style: theme.textStyle.caption
                    .standard(color: theme.textColorScheme.secondary)),
          ],
        ),
      ),
    );
  }
}
