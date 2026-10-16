import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_info.dart';
import 'design_system/environment_badge.dart';
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
            title: AppInfo.name,
            debugShowCheckedModeBanner: false,
            theme: workspaceTheme(Brightness.light),
            darkTheme: workspaceTheme(Brightness.dark),
            themeMode: settings.themeMode,
            builder: (context, child) {
              final builder = AppFlowyDefaultTheme();
              final media = MediaQuery.of(context);
              final theme = Theme.of(context);
              final dark = theme.brightness == Brightness.dark;
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
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle(
                      statusBarColor: Colors.transparent,
                      statusBarIconBrightness:
                          dark ? Brightness.light : Brightness.dark,
                      statusBarBrightness: theme.brightness,
                      systemNavigationBarColor: theme.scaffoldBackgroundColor,
                      systemNavigationBarIconBrightness:
                          dark ? Brightness.light : Brightness.dark,
                    ),
                    child: AppInfo.environment.badge == null
                        ? child!
                        : Stack(fit: StackFit.expand, children: [
                            child!,
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: media.viewPadding.bottom + 4,
                              child: EnvironmentBadge(
                                  environment: AppInfo.environment),
                            ),
                          ]),
                  ),
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
