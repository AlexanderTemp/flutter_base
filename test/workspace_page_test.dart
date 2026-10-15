import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/main.dart';
import 'package:flutter_workspace/workspace/presentation/workspace_widgets.dart';

void main() {
  testWidgets('adapta navegación móvil/escritorio y conserva las tareas',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    expect(find.byTooltip('Abrir navegación'), findsOneWidget);
    expect(find.byType(WorkspaceSidebar), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('new-task')));
    await tester.tap(find.byKey(const ValueKey('new-task')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit-task')));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un título'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Mi tarea de prueba');
    await tester.tap(find.byKey(const ValueKey('submit-task')));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceSidebar), findsOneWidget);
    expect(find.byTooltip('Abrir navegación'), findsNothing);
    expect(find.text('Mi tarea de prueba'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'MI TAREA');
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceTaskRow), findsOneWidget);
    await tester.tap(find.byType(WorkspaceTaskRow));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<WorkspaceTaskRow>(find.byType(WorkspaceTaskRow))
            .task
            .completed,
        isTrue);

    await tester.tap(find.byKey(const ValueKey('nav-pending')));
    await tester.pumpAndSettle();
    expect(find.text('No hay tareas que coincidan.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tema y pantalla estrecha con texto ampliado', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    final before = Theme.of(tester.element(find.byType(Scaffold))).brightness;
    await tester.tap(find.byTooltip('Cambiar tema'));
    await tester.pumpAndSettle();
    final after = Theme.of(tester.element(find.byType(Scaffold))).brightness;
    expect(after, isNot(before));

    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceSidebar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar no crea una tarea y el panel móvil filtra',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    await tester.ensureVisible(find.byKey(const ValueKey('new-task')));
    await tester.tap(find.byKey(const ValueKey('new-task')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'No guardar');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceTaskRow), findsNWidgets(3));
    expect(find.text('No guardar'), findsNothing);

    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-pending')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkspaceTaskRow), findsNWidgets(2));
    expect(find.byType(WorkspaceSidebar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('los botones AppFlowy y el diálogo funcionan con teclado',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const WorkspaceApp());
    final semantics = tester.ensureSemantics();
    await tester.pump();
    try {
      expect(find.bySemanticsLabel('Nueva tarea'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
    final buttonFocus = find.descendant(
      of: find.byKey(const ValueKey('new-task')),
      matching: find.byType(Focus),
    );
    tester.widget<Focus>(buttonFocus.first).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Creada con teclado');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Creada con teclado'), findsOneWidget);
    expect(find.byType(WorkspaceTaskRow), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
