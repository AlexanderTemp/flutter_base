import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import '../app_environment.dart';
import 'surfaces.dart';

/// Insignia flotante del entorno; no reserva espacio ni intercepta pulsaciones.
class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key, required this.environment});

  final AppEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final badge = environment.badge;
    if (badge == null) return const SizedBox.shrink();
    final t = AppFlowyTheme.of(context);
    final warning = environment == AppEnvironment.test;
    return IgnorePointer(
      // Material evita heredar el estilo de error de MaterialApp fuera del Navigator.
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: AfPill(
            text: badge,
            bg: warning ? t.fillColorScheme.warningLight : null,
            fg: warning ? t.textColorScheme.warning : null,
          ),
        ),
      ),
    );
  }
}
