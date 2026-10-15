import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceTask {
  const WorkspaceTask({
    required this.id,
    required this.title,
    this.completed = false,
  });

  final int id;
  final String title;
  final bool completed;
}

class WorkspaceState {
  WorkspaceState(Iterable<WorkspaceTask> tasks)
      : tasks = List.unmodifiable(tasks);

  final List<WorkspaceTask> tasks;
  int get completedCount => tasks.where((task) => task.completed).length;
}

class WorkspaceCubit extends Cubit<WorkspaceState> {
  WorkspaceCubit()
      : super(WorkspaceState([
          const WorkspaceTask(id: 0, title: 'Explorar el sistema de diseño'),
          const WorkspaceTask(id: 1, title: 'Crear mi primera pantalla'),
          const WorkspaceTask(
              id: 2, title: 'Entender el estado', completed: true),
        ]));

  // shortcut: datos en memoria, añadir persistencia antes de guardar trabajo real.
  int _nextId = 3;

  bool addTask(String title) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return false;
    emit(WorkspaceState([
      ...state.tasks,
      WorkspaceTask(id: _nextId++, title: cleanTitle),
    ]));
    return true;
  }

  void toggleTask(int id) {
    if (!state.tasks.any((task) => task.id == id)) return;
    emit(WorkspaceState([
      for (final task in state.tasks)
        if (task.id == id)
          WorkspaceTask(
              id: task.id, title: task.title, completed: !task.completed)
        else
          task,
    ]));
  }
}
