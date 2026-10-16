/// Entorno de compilación: `--dart-define=APP_ENV=development|test|production`.
///
/// Es independiente del modo debug/profile/release: una APK release puede ser
/// de pruebas. Sin la flag se asume `development`, nunca producción.
enum AppEnvironment {
  development(badge: 'Modo desarrollo'),
  test(badge: 'Versión de pruebas · puede contener errores'),
  production(badge: null);

  const AppEnvironment({required this.badge});

  /// Texto de la insignia global; `null` la oculta.
  final String? badge;

  static final current = _parse(
      const String.fromEnvironment('APP_ENV', defaultValue: 'development'));

  static AppEnvironment _parse(String raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    // Falla al arrancar: un error tipográfico no debe publicarse como otro entorno.
    throw StateError(
        'APP_ENV="$raw" no es válido; usa ${values.map((e) => e.name).join(', ')}.');
  }
}
