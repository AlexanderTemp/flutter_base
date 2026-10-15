import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'design_system/theme.dart';
import 'auth/application/auth_cubit.dart';
import 'settings/application/settings_cubit.dart';
import 'workspace/presentation/workspace_page.dart';

void main() => runApp(const WorkspaceApp());

class WorkspaceApp extends StatelessWidget {
  const WorkspaceApp({super.key, this.authRepository});
  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit()),
          BlocProvider(
              create: (_) => AuthCubit(authRepository ?? DemoAuthRepository())),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) => MaterialApp(
            title: 'Mi espacio',
            debugShowCheckedModeBanner: false,
            theme: workspaceTheme(Brightness.light),
            darkTheme: workspaceTheme(Brightness.dark),
            themeMode: settings.themeMode,
            builder: (context, child) {
              final builder = AppFlowyDefaultTheme();
              final media = MediaQuery.of(context);
              return AppFlowyTheme(
                data: Theme.of(context).brightness == Brightness.dark
                    ? builder.dark()
                    : builder.light(),
                child: MediaQuery(
                  // Conserva la ampliación accesible del sistema operativo.
                  data: media.copyWith(
                    textScaler:
                        _ScaledTextScaler(media.textScaler, settings.textScale),
                  ),
                  child: child!,
                ),
              );
            },
            home: WorkspacePage(
              onToggleTheme: () {
                final isDark = settings.themeMode == ThemeMode.dark ||
                    (settings.themeMode == ThemeMode.system &&
                        WidgetsBinding.instance.platformDispatcher
                                .platformBrightness ==
                            Brightness.dark);
                context
                    .read<SettingsCubit>()
                    .setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
              },
            ),
          ),
        ),
      );
}

class _ScaledTextScaler extends TextScaler {
  const _ScaledTextScaler(this.system, this.factor);
  final TextScaler system;
  final double factor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(14) / 14;
}
