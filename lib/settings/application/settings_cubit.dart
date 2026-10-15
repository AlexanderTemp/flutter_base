import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.textScale = 1,
    this.compact = false,
    this.showCompleted = true,
    this.workspaceName = 'Mi espacio',
    this.profileName = 'Mi perfil',
    this.profileBio = '',
    this.avatarColor = 0,
  });

  final ThemeMode themeMode;
  final double textScale;
  final bool compact;
  final bool showCompleted;
  final String workspaceName;
  final String profileName;
  final String profileBio;
  final int avatarColor;

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? compact,
    bool? showCompleted,
    String? workspaceName,
    String? profileName,
    String? profileBio,
    int? avatarColor,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        textScale: textScale ?? this.textScale,
        compact: compact ?? this.compact,
        showCompleted: showCompleted ?? this.showCompleted,
        workspaceName: workspaceName ?? this.workspaceName,
        profileName: profileName ?? this.profileName,
        profileBio: profileBio ?? this.profileBio,
        avatarColor: avatarColor ?? this.avatarColor,
      );
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  // shortcut: preferencias en memoria, añadir almacenamiento al persistir la base.
  void setTheme(ThemeMode value) => emit(state.copyWith(themeMode: value));

  void setTextScale(double value) {
    if (!const [1.0, 1.15, 1.3].contains(value)) return;
    emit(state.copyWith(textScale: value));
  }

  void setCompact(bool value) => emit(state.copyWith(compact: value));
  void setShowCompleted(bool value) =>
      emit(state.copyWith(showCompleted: value));

  bool renameWorkspace(String value) {
    final name = value.trim();
    if (name.isEmpty || name.characters.length > 40) return false;
    emit(state.copyWith(workspaceName: name));
    return true;
  }

  bool updateProfile(String name, String bio, int color) {
    final cleanName = name.trim();
    final cleanBio = bio.trim();
    if (cleanName.isEmpty ||
        cleanName.characters.length > 40 ||
        cleanBio.characters.length > 160 ||
        color < 0 ||
        color > 3) {
      return false;
    }
    emit(state.copyWith(
        profileName: cleanName, profileBio: cleanBio, avatarColor: color));
    return true;
  }

  void reset() => emit(SettingsState(
      profileName: state.profileName,
      profileBio: state.profileBio,
      avatarColor: state.avatarColor));
}
