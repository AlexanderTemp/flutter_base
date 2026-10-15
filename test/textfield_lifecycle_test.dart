import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'el campo cambia de controlador sin perder valor ni liberar recursos externos',
      (tester) async {
    final first = TextEditingController(text: 'Primero');
    final second = TextEditingController(text: 'Segundo');
    var validations = 0;
    Widget field(TextEditingController? controller, {bool obscure = false}) =>
        MaterialApp(
          home: AppFlowyTheme(
              data: AppFlowyDefaultTheme().light(),
              child: Scaffold(
                body: AFTextField(
                    controller: controller,
                    obscureText: obscure,
                    validator: (_) {
                      validations++;
                      return (false, '');
                    }),
              )),
        );

    await tester.pumpWidget(field(null));
    final owned = tester.widget<TextField>(find.byType(TextField)).controller!;
    await tester.pumpWidget(field(first));
    expect(tester.widget<TextField>(find.byType(TextField)).controller,
        same(first));
    expect(() => owned.addListener(() {}), throwsFlutterError);

    await tester.pumpWidget(field(second, obscure: true));
    expect(tester.widget<TextField>(find.byType(TextField)).controller,
        same(second));
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    final before = validations;
    first.text = 'Ya no pertenece al campo';
    expect(validations, before);
    second.value = const TextEditingValue(
        text: 'Editado', selection: TextSelection.collapsed(offset: 3));
    expect(validations, before + 1);
    await tester.pump();

    await tester.pumpWidget(field(null));
    final replacement =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    expect(replacement, isNot(same(second)));
    expect(replacement.value, second.value);
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(() => replacement.addListener(() {}), throwsFlutterError);
    first.text = 'Externo válido';
    second.text = 'Externo válido';
    first.dispose();
    second.dispose();
  });
}
