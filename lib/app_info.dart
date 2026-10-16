import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Identidad visible de la base; adaptar junto a los nombres nativos al crear un fork.
class AppInfo {
  static const name = 'Mi espacio';
  static const developer = 'Aynicode';

  static Future<String> loadVersion() async {
    try {
      // shortcut: versión del proyecto; usar metadatos nativos al sobrescribir la versión de compilación.
      final manifest = await rootBundle.loadString('pubspec.yaml');
      return RegExp(r'^version:\s*(\S+)', multiLine: true)
              .firstMatch(manifest)
              ?.group(1) ??
          'No disponible';
    } catch (e) {
      debugPrint('Base Flutter: versión no disponible: $e');
      return 'No disponible';
    }
  }
}
