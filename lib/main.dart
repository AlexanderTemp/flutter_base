// App de Forex: noticias fuertes de Forex Factory con filtros, auto-refresco
// y notificaciones. Punto de entrada.
import 'package:flutter/material.dart';

import 'forex/forex_page.dart';

void main() => runApp(const ForexApp());

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
    const seed = Color(0xFF1565C0);
    return MaterialApp(
      title: 'Forex Noticias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      themeMode: _mode,
      home: ForexHomePage(onToggleTheme: _toggleTheme),
    );
  }
}
