// Motor de reglas que interpreta una noticia roja SIN IA.
//
// Usa la regla "Usual Effect" que publica Forex Factory
// ("'Actual' greater than 'Forecast' is good for currency" o la inversa)
// y compara actual vs forecast para decidir si el dato es alcista o bajista
// para la divisa. Añade tendencia vs el dato anterior.
import 'ff_models.dart';

enum Bias { alcista, bajista, neutral, sinDato }

class FfAnalysis {
  FfAnalysis({
    required this.bias,
    required this.verdict,
    required this.trend,
    required this.usualEffect,
    required this.why,
  });

  final Bias bias;
  final String verdict;
  final String trend;
  final String usualEffect;
  final String why;
}

class FfAnalyzer {
  /// Analiza un evento ya publicado usando su detalle (regla + contexto).
  static FfAnalysis analyze(FfEvent e, FfDetail detail) {
    final usual = detail.usualEffect;
    final u = usual.toLowerCase();

    // Dirección de la regla: +1 = dato más alto es alcista; -1 = más bajo lo es.
    var rule = 0;
    if (u.contains('greater') && u.contains('good')) {
      rule = 1;
    } else if ((u.contains('less') || u.contains('lower')) && u.contains('good')) {
      rule = -1;
    }

    final a = toNum(e.actual);
    final f = toNum(e.forecast);
    final p = toNum(e.previous);

    var bias = Bias.neutral;
    String verdict;

    if (a == null) {
      bias = Bias.sinDato;
      verdict = 'Evento cualitativo (discurso/sin cifra). Vigila el tono.';
    } else if (f != null && rule != 0) {
      final diff = a - f;
      final signed = diff * rule;
      if (diff.abs() < 1e-9) {
        bias = Bias.neutral;
        verdict = 'En línea con lo esperado.';
      } else if (signed > 0) {
        bias = Bias.alcista;
        verdict = 'Mejor de lo esperado → ALCISTA para ${e.currency}'
            ' (sorpresa ${_fmtSigned(diff)}).';
      } else {
        bias = Bias.bajista;
        verdict = 'Peor de lo esperado → BAJISTA para ${e.currency}'
            ' (sorpresa ${_fmtSigned(diff)}).';
      }
    } else if (e.betterWorse != 0) {
      // Respaldo: el propio veredicto verde/rojo de FF (1 mejor, 2 peor).
      final better = e.betterWorse == 1;
      bias = better ? Bias.alcista : Bias.bajista;
      verdict = '${better ? 'Mejor' : 'Peor'} de lo esperado → '
          '${better ? 'ALCISTA' : 'BAJISTA'} para ${e.currency} (según FF).';
    } else {
      verdict = 'Dato publicado; sin forecast claro para comparar.';
    }

    // Tendencia vs dato anterior.
    var trend = '';
    if (a != null && p != null) {
      if (a > p) {
        trend = 'Sube vs anterior (${e.actual} > ${e.previous}).';
      } else if (a < p) {
        trend = 'Baja vs anterior (${e.actual} < ${e.previous}).';
      } else {
        trend = 'Igual que el anterior (${e.actual}).';
      }
    }

    final why = detail.why;
    return FfAnalysis(
      bias: bias,
      verdict: verdict,
      trend: trend,
      usualEffect: usual,
      why: why.length > 240 ? '${why.substring(0, 240)}…' : why,
    );
  }

  /// '0.3%', '-39.3K', '1.2M', '<0.1%' → double. null si no se puede.
  static double? toNum(String? x) {
    if (x == null) return null;
    var s = x
        .trim()
        .replaceAll(',', '')
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('%', '');
    final m = RegExp(r'^(-?\d+(?:\.\d+)?)\s*([KkMmBbTt]?)').firstMatch(s);
    if (m == null) return null;
    final v = double.parse(m.group(1)!);
    const mult = {'k': 1e3, 'm': 1e6, 'b': 1e9, 't': 1e12};
    return v * (mult[m.group(2)!.toLowerCase()] ?? 1);
  }

  static String _fmtSigned(double x) {
    final sign = x > 0 ? '+' : '';
    final abs = x.abs();
    if (abs >= 1000) {
      for (final e in const [
        ['T', 1e12],
        ['B', 1e9],
        ['M', 1e6],
        ['K', 1e3]
      ]) {
        final d = e[1] as double;
        if (abs >= d) return '$sign${(x / d).toStringAsFixed(2)}${e[0]}';
      }
    }
    // Quita el .0 sobrante.
    final str = x.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return '$sign$str';
  }
}
