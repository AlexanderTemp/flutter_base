import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import '../../design_system/app_logo.dart';
import '../../design_system/workspace_icon.dart';
import '../../design_system/workspace_controls.dart';
import '../application/workspace_cubit.dart';

enum TaskFilter {
  all('Todas', 'type_page'),
  pending('Pendientes', 'type_todo'),
  completed('Completadas', 'toolbar_check');

  const TaskFilter(this.label, this.icon);
  final String label;
  final String icon;
}

enum WorkspaceDestination {
  tasks('Tareas', Icons.home_outlined),
  search('Buscar', Icons.search),
  components('Componentes', Icons.widgets_outlined),
  settings('Ajustes', Icons.settings_outlined);

  const WorkspaceDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

class WorkspaceBottomNavigation extends StatelessWidget {
  const WorkspaceBottomNavigation({
    super.key,
    required this.destination,
    required this.onNavigate,
    required this.onCreate,
  });

  final WorkspaceDestination destination;
  final ValueChanged<WorkspaceDestination> onNavigate;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    Widget item(WorkspaceDestination value) => Expanded(
          child: WorkspaceChoice(
            key: ValueKey('bottom-${value.name}'),
            label: value == WorkspaceDestination.components ? 'Diseño' : value.label,
            icon: value.icon,
            selected: destination == value,
            vertical: true,
            onTap: () => onNavigate(value),
          ),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceContainerColorScheme.layer01,
        border: Border(top: BorderSide(color: theme.borderColorScheme.primary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            item(WorkspaceDestination.tasks),
            item(WorkspaceDestination.search),
            item(WorkspaceDestination.components),
            Expanded(
              child: WorkspaceChoice(
                key: const ValueKey('bottom-create'),
                label: 'Crear',
                icon: Icons.add_circle_outline,
                selected: false,
                vertical: true,
                onTap: onCreate,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class WorkspaceIconButton extends StatelessWidget {
  const WorkspaceIconButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Semantics(
          button: true,
          container: true,
          label: label,
          child: AFGhostButton.normal(
            onTap: onTap,
            padding: const EdgeInsets.all(12),
            builder: (context, _, __) => Icon(icon,
                size: 20,
                color: AppFlowyTheme.of(context).iconColorScheme.secondary),
          ),
        ),
      );
}

class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar(
      {super.key,
      required this.filter,
      required this.state,
      required this.onSelect,
      required this.onCreate,
      required this.workspaceName,
      required this.destination,
      required this.onNavigate});

  final TaskFilter filter;
  final WorkspaceState state;
  final ValueChanged<TaskFilter> onSelect;
  final VoidCallback onCreate;
  final String workspaceName;
  final WorkspaceDestination destination;
  final ValueChanged<WorkspaceDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return ColoredBox(
      color: theme.surfaceContainerColorScheme.layer01,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const AppLogo(),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(workspaceName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textStyle.body
                            .enhanced(color: theme.textColorScheme.primary))),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final destination in WorkspaceDestination.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: WorkspaceChoice(
                        key: ValueKey('sidebar-${destination.name}'),
                        label: destination.label,
                        icon: destination.icon,
                        selected: this.destination == destination,
                        expand: true,
                        onTap: () => onNavigate(destination),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    child: Text('ESPACIO PRIVADO',
                        style: theme.textStyle.caption
                            .enhanced(color: theme.textColorScheme.secondary)),
                  ),
                  for (final item in TaskFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Semantics(
                        button: true,
                        container: true,
                        selected: destination == WorkspaceDestination.tasks &&
                            filter == item,
                        child: AFBaseButton(
                          key: ValueKey('nav-${item.name}'),
                          onTap: () => onSelect(item),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          borderRadius: theme.borderRadius.m,
                          borderColor: (_, __, ___, ____) => Colors.transparent,
                          backgroundColor: (_, hover, __) =>
                              destination == WorkspaceDestination.tasks &&
                                      filter == item
                                  ? theme.fillColorScheme.themeSelect
                                  : hover
                                      ? theme.fillColorScheme.contentHover
                                      : Colors.transparent,
                          builder: (context, _, __) => Row(children: [
                            WorkspaceIcon(item.icon,
                                color:
                                    destination == WorkspaceDestination.tasks &&
                                            filter == item
                                        ? theme.textColorScheme.action
                                        : null),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(item.label,
                                    style: theme.textStyle.body.standard(
                                        color: destination ==
                                                    WorkspaceDestination
                                                        .tasks &&
                                                filter == item
                                            ? theme.textColorScheme.action
                                            : theme.textColorScheme.primary))),
                            Text(
                                '${switch (item) {
                                  TaskFilter.all => state.tasks.length,
                                  TaskFilter.pending =>
                                    state.tasks.length - state.completedCount,
                                  TaskFilter.completed => state.completedCount,
                                }}',
                                style: theme.textStyle.caption.standard(
                                    color: theme.textColorScheme.secondary)),
                          ]),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    container: true,
                    child: AFGhostButton.normal(
                      onTap: onCreate,
                      padding: const EdgeInsets.all(12),
                      builder: (context, _, __) => Row(children: [
                        Icon(Icons.add,
                            size: 20, color: theme.iconColorScheme.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('Añadir una tarea',
                                style: theme.textStyle.body.standard(
                                    color: theme.textColorScheme.secondary))),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                  'Tu espacio, a tu manera.\nDemo local · Sin sincronización',
                  style: theme.textStyle.caption
                      .standard(color: theme.textColorScheme.secondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkspaceTaskRow extends StatelessWidget {
  const WorkspaceTaskRow(
      {super.key,
      required this.task,
      required this.onToggle,
      this.compact = false});

  final WorkspaceTask task;
  final VoidCallback onToggle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Semantics(
      label: task.title,
      checked: task.completed,
      onTap: onToggle,
      excludeSemantics: true,
      child: AFBaseButton(
        onTap: onToggle,
        padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 12 : 16),
        borderRadius: theme.borderRadius.m,
        borderColor: (_, __, ___, ____) => Colors.transparent,
        backgroundColor: (_, hover, __) =>
            hover ? theme.fillColorScheme.contentHover : Colors.transparent,
        builder: (context, _, __) => Row(children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: task.completed
                  ? theme.fillColorScheme.themeThick
                  : Colors.transparent,
              border: Border.all(
                  color: task.completed
                      ? theme.fillColorScheme.themeThick
                      : theme.iconColorScheme.tertiary),
              borderRadius: BorderRadius.circular(theme.borderRadius.xs),
            ),
            child: task.completed
                ? WorkspaceIcon('toolbar_check',
                    size: 16, color: theme.textColorScheme.onFill)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(task.title,
                  style: theme.textStyle.body
                      .standard(
                          color: task.completed
                              ? theme.textColorScheme.secondary
                              : theme.textColorScheme.primary)
                      .copyWith(
                          decoration: task.completed
                              ? TextDecoration.lineThrough
                              : null))),
        ]),
      ),
    );
  }
}
