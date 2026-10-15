import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import 'design_system/theme.dart';
import 'workspace/presentation/workspace_page.dart';

void main() => runApp(const WorkspaceApp());

class WorkspaceApp extends StatefulWidget {
  const WorkspaceApp({super.key});

  @override
  State<WorkspaceApp> createState() => _WorkspaceAppState();
}

class _WorkspaceAppState extends State<WorkspaceApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi espacio',
      debugShowCheckedModeBanner: false,
      theme: workspaceTheme(Brightness.light),
      darkTheme: workspaceTheme(Brightness.dark),
      themeMode: _themeMode,
      builder: (context, child) {
        final builder = AppFlowyDefaultTheme();
        return AppFlowyTheme(
          data: Theme.of(context).brightness == Brightness.dark
              ? builder.dark()
              : builder.light(),
          child: child!,
        );
      },
      home: WorkspacePage(
        onToggleTheme: () {
          final isDark = _themeMode == ThemeMode.dark ||
              (_themeMode == ThemeMode.system &&
                  WidgetsBinding
                          .instance.platformDispatcher.platformBrightness ==
                      Brightness.dark);
          setState(() {
            _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
          });
        },
      ),
    );
  }
}
