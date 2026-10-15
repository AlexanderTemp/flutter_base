// Análisis por plantillas (sin IA) para noticias de alto impacto.
// A partir del tipo de indicador y de forecast vs previo, estima la dirección
// esperada para la divisa y una reacción TÍPICA en cripto.
//
// ⚠️ Es una heurística educativa, NO consejo financiero. La reacción real varía.
import '../ff_analyzer.dart';
import '../ff_models.dart';

enum ExpectedBias { alcista, bajista, neutral, sinDato }

class ImpactAnalysis {
  ImpactAnalysis({
    required this.category,
    required this.measures,
    required this.expectation,
    required this.cryptoReaction,
    required this.bias,
  });

  final String category; // "Inflación", "Empleo"…
  final String measures; // qué mide, en una línea
  final String expectation; // qué se espera (forecast vs previo)
  final String cryptoReaction; // reacción típica en cripto
  final ExpectedBias bias; // dirección esperada para la divisa
}

class _Kind {
  const _Kind(this.category, this.measures, this.higherIsGood,
      {this.qualitative = false});
  final String category;
  final String measures;
  final bool higherIsGood; // dato más alto = bueno para la divisa
  final bool qualitative; // discurso/sin cifra
}

class ImpactAnalyzer {
  /// Clasifica el indicador por palabras clave del nombre.
  static _Kind _classify(String name) {
    final n = name.toLowerCase();
    bool has(List<String> ks) => ks.any(n.contains);

    if (has(['speaks', 'speech', 'testimony', 'statement', 'press conf'])) {
      return const _Kind('Discurso', 'Intervención de un banquero central; '
          'importa el tono (hawkish/dovish).', true, qualitative: true);
    }
    if (has(['unemployment rate'])) {
      return const _Kind('Empleo', 'Tasa de paro: más alta = peor para la economía.',
          false);
    }
    if (has(['jobless', 'claims'])) {
      return const _Kind('Empleo', 'Solicitudes de desempleo: más = peor.', false);
    }
    if (has(['nonfarm', 'payroll', 'employment change', 'adp'])) {
      return const _Kind('Empleo', 'Creación de empleo: más = economía fuerte.',
          true);
    }
    if (has(['cpi', 'ppi', 'inflation', 'price index'])) {
      return const _Kind('Inflación',
          'Precios al consumo/producción; inflación alta presiona a subir tipos.',
          true);
    }
    if (has(['gdp', 'growth'])) {
      return const _Kind('Crecimiento', 'Producto interior bruto (actividad).',
          true);
    }
    if (has(['retail sales'])) {
      return const _Kind('Consumo', 'Ventas minoristas: gasto del consumidor.',
          true);
    }
    if (has(['pmi', 'manufacturing', 'ism', 'industrial', 'production'])) {
      return const _Kind('Actividad', 'Actividad manufacturera/servicios.', true);
    }
    if (has(['rate', 'cash rate', 'funds rate', 'interest'])) {
      return const _Kind('Tipos', 'Decisión de tipos de interés.', true);
    }
    return const _Kind('Macro', 'Indicador macroeconómico de alto impacto.', true);
  }

  static ImpactAnalysis analyze(FfEvent e) {
    final kind = _classify(e.name);

    if (kind.qualitative) {
      return ImpactAnalysis(
        category: kind.category,
        measures: kind.measures,
        expectation: 'Sin cifra: el impacto depende del tono del ponente '
            '(más duro = alcista para ${e.currency}; más suave = bajista).',
        cryptoReaction: _cryptoLine(e.currency, ExpectedBias.sinDato),
        bias: ExpectedBias.sinDato,
      );
    }

    final f = FfAnalyzer.toNum(e.forecast);
    final p = FfAnalyzer.toNum(e.previous);
    ExpectedBias bias = ExpectedBias.neutral;
    String expectation;

    if (f == null || p == null) {
      expectation = 'Se publica a las '
          '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}. '
          'Compara el dato real con el forecast (${e.forecast.isEmpty ? "—" : e.forecast}).';
    } else {
      final higherExpected = f > p;
      final strongerCurrency =
          (higherExpected && kind.higherIsGood) || (!higherExpected && !kind.higherIsGood);
      if (f == p) {
        bias = ExpectedBias.neutral;
        expectation = 'Se espera igual que el dato previo (${e.previous}).';
      } else {
        bias = strongerCurrency ? ExpectedBias.alcista : ExpectedBias.bajista;
        expectation = 'Se espera que ${higherExpected ? "suba" : "baje"} '
            '(forecast ${e.forecast} vs previo ${e.previous}) → '
            '${strongerCurrency ? "favorable" : "desfavorable"} para ${e.currency}.';
      }
    }

    return ImpactAnalysis(
      category: kind.category,
      measures: kind.measures,
      expectation: expectation,
      cryptoReaction: _cryptoLine(e.currency, bias),
      bias: bias,
    );
  }

  /// Heurística USD-céntrica: cripto suele correlacionar inverso con el dólar.
  static String _cryptoLine(String currency, ExpectedBias bias) {
    if (currency != 'USD') {
      return 'Efecto directo en cripto limitado: el gran driver es el USD y el '
          'apetito de riesgo global. Vigila el índice dólar (DXY).';
    }
    switch (bias) {
      case ExpectedBias.alcista:
        return '📉 USD fuerte suele PRESIONAR a BTC/cripto a la baja '
            '(correlación inversa con el dólar; expectativa de tipos altos).';
      case ExpectedBias.bajista:
        return '📈 USD débil suele dar VIENTO DE COLA a BTC/cripto '
            '(más apetito por riesgo).';
      case ExpectedBias.neutral:
        return 'Sin sorpresa, poca reacción esperada en cripto.';
      case ExpectedBias.sinDato:
        return 'Si el tono endurece el USD → presión en cripto; si lo suaviza → '
            'alivio para cripto.';
    }
  }
}
