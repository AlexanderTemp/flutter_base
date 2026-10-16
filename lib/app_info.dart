import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;

import 'app_environment.dart';

/// Identidad visible de la base; adaptar junto a los nombres nativos al crear un fork.
class AppInfo {
  static const name = 'Flutter Base';
  static const logoAsset = 'assets/branding/logo.png';
  static const developer = 'AyniCode';
  static final environment = AppEnvironment.current;
  static const buildMode =
      kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug');

  static Future<String> loadVersion() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final version = await const MethodChannel('app/info')
            .invokeMethod<String>('version');
        if (version != null && version.isNotEmpty) return version;
      } catch (e) {
        debugPrint('Base Flutter: versión Android no disponible: $e');
      }
    }
    try {
      // shortcut: fuera de Android se usa pubspec; leer metadatos nativos si se sobrescribe la versión al compilar.
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
