// App de Forex: noticias fuertes de Forex Factory con filtros, auto-refresco
// y notificaciones. Usa el design system AppFlowy (tema propio).
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'design_system/theme.dart';
import 'forex/live/live_notification.dart';
import 'forex/forex_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // El foreground service solo existe en móvil.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    FlutterForegroundTask.initCommunicationPort();
    LiveNotifier.configure();
  }
  runApp(const ForexApp());
}

class ForexApp extends StatefulWidget {
  const ForexApp({super.key});

  @override
  State<ForexApp> createState() => _ForexAppState();
}

class _ForexAppState extends State<ForexApp> {
  ThemeMode _mode = ThemeMode.system;

  void _toggleTheme() {
    final isDark = _mode == ThemeMode.dark ||
        (_mode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    setState(() => _mode = isDark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forex Noticias',
      debugShowCheckedModeBanner: false,
      theme: workspaceTheme(Brightness.light),
      darkTheme: workspaceTheme(Brightness.dark),
      themeMode: _mode,
      builder: (context, child) {
        final builder = AppFlowyDefaultTheme();
        return AppFlowyTheme(
          data: Theme.of(context).brightness == Brightness.dark
              ? builder.dark()
              : builder.light(),
          child: child!,
        );
      },
      home: ForexHomePage(onToggleTheme: _toggleTheme),
    );
  }
}
