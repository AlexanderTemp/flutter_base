import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workspace/settings/application/settings_cubit.dart';

void main() {
  test('perfil validado y restablecimiento de apariencia conserva identidad',
      () {
    final cubit = SettingsCubit();
    addTearDown(cubit.close);
    final initial = cubit.state;
    expect(cubit.updateProfile('', '', 0), isFalse);
    expect(cubit.updateProfile('a' * 41, '', 0), isFalse);
    expect(cubit.updateProfile('Nombre', 'a' * 161, 0), isFalse);
    expect(cubit.updateProfile('Nombre', '', 4), isFalse);
    expect(cubit.state, same(initial));
    expect(cubit.updateProfile(' Alexander ', ' Flutter ', 3), isTrue);
    cubit.setCompact(true);
    cubit.reset();
    expect(cubit.state.profileName, 'Alexander');
    expect(cubit.state.profileBio, 'Flutter');
    expect(cubit.state.avatarColor, 3);
    expect(cubit.state.compact, isFalse);
    expect(initial.profileName, 'Mi perfil');
  });
  test('valida preferencias y conserva la fotografía anterior', () {
    final cubit = SettingsCubit();
    addTearDown(cubit.close);
    final initial = cubit.state;

    expect(cubit.renameWorkspace('   '), isFalse);
    expect(cubit.renameWorkspace('a' * 41), isFalse);
    cubit.setTextScale(double.nan);
    cubit.setTextScale(8);
    expect(cubit.state, same(initial));

    expect(cubit.renameWorkspace('🤠' * 40), isTrue);
    expect(cubit.renameWorkspace('🤠' * 41), isFalse);

    expect(cubit.renameWorkspace('  Mi estudio  '), isTrue);
    cubit.setTheme(ThemeMode.dark);
    cubit.setTextScale(1.3);
    cubit.setCompact(true);
    cubit.setShowCompleted(false);
    expect(cubit.state.workspaceName, 'Mi estudio');
    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.textScale, 1.3);
    expect(cubit.state.compact, isTrue);
    expect(cubit.state.showCompleted, isFalse);
    expect(initial.workspaceName, 'Mi espacio');
    expect(initial.compact, isFalse);

    cubit.reset();
    expect(cubit.state.workspaceName, 'Mi espacio');
    expect(cubit.state.themeMode, ThemeMode.system);
    expect(cubit.state.textScale, 1);
    expect(cubit.state.compact, isFalse);
    expect(cubit.state.showCompleted, isTrue);
  });
}
