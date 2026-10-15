import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/workspace/application/workspace_cubit.dart';

void main() {
  test('rechaza títulos vacíos y normaliza los válidos', () {
    final controller = WorkspaceCubit();
    addTearDown(controller.close);
    final initial = controller.state;
    final initialCount = controller.state.tasks.length;

    expect(controller.addTask('   '), isFalse);
    expect(controller.state.tasks.length, initialCount);
    expect(controller.state, same(initial));
    expect(controller.addTask('  Mi proyecto  '), isTrue);
    expect(controller.state.tasks.last.title, 'Mi proyecto');
    expect(controller.state.tasks.map((task) => task.id).toSet().length,
        controller.state.tasks.length);
    expect(initial.tasks.length, initialCount);
    expect(() => controller.state.tasks.clear(), throwsUnsupportedError);
  });

  test('completar es reversible y un id inexistente no altera el estado', () {
    final controller = WorkspaceCubit();
    addTearDown(controller.close);
    final completed = controller.state.completedCount;
    final task = controller.state.tasks.first;

    controller.toggleTask(task.id);
    expect(controller.state.completedCount, completed + 1);
    expect(controller.state.tasks.first.completed, isTrue);
    controller.toggleTask(task.id);
    expect(controller.state.completedCount, completed);
    controller.toggleTask(-1);
    expect(controller.state.completedCount, completed);
  });
}
