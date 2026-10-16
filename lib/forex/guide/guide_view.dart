import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import '../ui.dart';

/// Guía local: disponible sin conexión y sin consultas adicionales a las fuentes.
class GuideView extends StatefulWidget {
  const GuideView({super.key});

  @override
  State<GuideView> createState() => _GuideViewState();
}

class _GuideViewState extends State<GuideView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u');

  static const _topics = [
    (
      'Por dónde empezar',
      '1. En Próximas, elige Hoy o Semana y revisa los eventos de las divisas que te interesan. Las horas son las de tu dispositivo.\n\n'
          '2. En Noticias, cambia entre el calendario de Forex Factory y los titulares RSS. Son fuentes distintas.\n\n'
          '3. En Análisis, lee la explicación de los eventos de alto impacto para entender el contexto.\n\n'
          'Desliza los filtros hacia los lados para verlos todos. Tira de la lista hacia abajo para actualizar. En Ajustes puedes elegir tus criptomonedas.',
    ),
    (
      'Real, previsión y previo',
      'Real (actual): la cifra que se acaba de publicar. En inglés, “actual” significa real, no previsión.\n\n'
          'El feed de calendario usado por Tradex no incluye el dato real: publica la programación, previsión y previo. Un aviso a la hora del evento es un recordatorio, no una confirmación de que ya salió la cifra.\n\n'
          'Previsión (forecast): lo que se esperaba antes de la publicación.\n\n'
          'Previo (previous): el dato del período anterior; a veces se revisa.\n\n'
          'Ejemplo: inflación previa 3,0 %, previsión 2,8 % y real 2,9 %. Bajó frente al período anterior, pero salió por encima de lo esperado. Son comparaciones distintas.\n\n'
          'Un guion o campo vacío significa que no hay cifra disponible; no equivale a cero. Comprueba también las unidades: %, miles (K), millones (M) o miles de millones (B).',
    ),
    (
      'Qué significan los impactos y los colores',
      'Rojo: alto impacto esperado. Naranja: medio. Amarillo: bajo. Festivo: puede cambiar la actividad o los horarios del mercado.\n\n'
          'El impacto viene de Forex Factory. Describe la relevancia esperada del evento, no si el precio subirá o bajará. Un evento rojo no significa una caída.\n\n'
          '“Sin impacto publicado” en un titular RSS significa que esa fuente no aporta la clasificación. No quiere decir que la noticia sea poco importante.',
    ),
    (
      'Inflación: CPI / IPC y PPI',
      'CPI o IPC mide los precios que pagan los consumidores. PPI mide precios desde el lado de los productores. La inflación refleja cómo cambian los precios, no cuánto cuesta todo en términos absolutos.\n\n'
          'Mensual compara con el mes anterior; interanual compara con el mismo mes del año pasado. “Core” o subyacente suele excluir alimentos y energía.\n\n'
          'Una sorpresa de inflación puede cambiar las expectativas de tipos de interés. La reacción depende del contexto y de lo que el mercado ya esperaba.',
    ),
    (
      'Empleo, PIB y PMI',
      'NFP (Nonfarm Payrolls): cambio del empleo no agrícola en Estados Unidos. No es la tasa de desempleo.\n\n'
          'Tasa de desempleo: proporción de personas activas que buscan trabajo y no lo encuentran. Jobless Claims: solicitudes de subsidio de desempleo.\n\n'
          'PIB / GDP: valor de la producción de una economía. Revisa si el dato es trimestral, interanual o anualizado antes de comparar.\n\n'
          'PMI: encuesta de actividad empresarial. En general, por encima de 50 indica expansión frente al mes anterior y por debajo, contracción. No es un porcentaje de crecimiento del PIB.',
    ),
    (
      'Tipos de interés, dólar y criptomonedas',
      'Los bancos centrales, como la Reserva Federal (Fed) de Estados Unidos o el Banco Central Europeo (BCE), fijan tipos de interés de referencia. Una subida puede encarecer el crédito; una bajada puede abaratarlo. Importa tanto la decisión como lo que se diga sobre el futuro.\n\n'
          'Hawkish: tono más favorable a endurecer la política monetaria. Dovish: tono más favorable a relajarla.\n\n'
          'DXY es un índice del dólar frente a una cesta de divisas. Un dólar fuerte a veces coincide con presión sobre las criptomonedas, pero esa relación cambia y puede romperse. No es una regla automática.',
    ),
    (
      'Cómo leer los precios y la variación 24 h',
      'BTC, ETH y los demás símbolos identifican activos. En la cinta de precios, las cotizaciones se muestran en dólares estadounidenses.\n\n'
          'El porcentaje de 24 h compara el precio con el de aproximadamente 24 horas antes. No es necesariamente la variación desde medianoche.\n\n'
          'Ejemplo: si pasó de 100 a 105 dólares, la variación es +5 %. Si tienes una cantidad del activo, ese porcentaje no incluye tus comisiones ni indica tu ganancia personal.\n\n'
          'Verde y + indican subida; rojo y − indican bajada. Las fuentes pueden tener retrasos o mostrar la última cotización disponible.',
    ),
    (
      'USD/BOB: qué cotización muestra Tradex',
      'USD es el dólar estadounidense y BOB es el boliviano. “USD/BOB · Bs 6,96”, por ejemplo, se lee como 6,96 bolivianos por un dólar; la cifra es solo ilustrativa.\n\n'
          'Tradex consulta la cotización oficial publicada por el Banco Central de Bolivia. No representa necesariamente una oferta de banco, casa de cambio, mercado paralelo o P2P.\n\n'
          'Esta serie TCO corresponde a la mediana ponderada por monto de las compras de dólares publicadas por el BCB. Revisa la vigencia del dato y la cotización real de la operación que quieras comparar.\n\n'
          'En Boliviano puedes ver el valor actual y los últimos 7, 30 o 50 registros, todos los disponibles o un rango de fechas. Cada movimiento compara con el registro anterior; la variación del rango compara su primer y último valor.\n\n'
          'Si USD/BOB sube, hacen falta más bolivianos por dólar: el BOB se debilita frente al USD. Si baja, se fortalece. Los días sin cambio también cuentan como registros; no se inventan fechas faltantes.',
    ),
    (
      'Datos anteriores y errores de conexión',
      '“Datos anteriores” indica que estás viendo la última descarga correcta guardada, no una consulta nueva. La fecha de guardado no es la fecha del evento.\n\n'
          'Toca ese aviso para ver el motivo del fallo y reintentar. Si hay una copia disponible, “Mostrar datos anteriores” permite abrirla. Sin una descarga previa no hay copia que recuperar.\n\n'
          'Con la actualización automática activa, el calendario vuelve a intentar la consulta cada 60 segundos y reemplaza la copia cuando obtiene datos nuevos. Un error 429 significa que la fuente está limitando las consultas; insistir muchas veces no ayuda.\n\n'
          'Si la copia corresponde a otra fecha, revisa Semana: Hoy puede no contener esos eventos.',
    ),
    (
      'Cómo interpretar Análisis y las notificaciones',
      'Análisis usa plantillas según el nombre del indicador y sus cifras. Compara previsión con previo cuando están disponibles; eso describe una expectativa, no la sorpresa real tras la publicación.\n\n'
          '“Alcista” significa una inclinación al alza para la divisa analizada; “bajista”, a la baja. No implica que todas las criptomonedas vayan en esa misma dirección.\n\n'
          'Las explicaciones son orientativas: no calculan probabilidades ni garantizan precios. Lee el dato real, su previsión, las revisiones y el contexto juntos.\n\n'
          'En Ajustes, “Contenido del panel” permite elegir precios, variación 24 h, USD/BOB y eventos; la moneda destacada aparece primero.\n\n'
          'Activa “Alto impacto” para recibir recordatorios del calendario a la hora del evento, 5 o 15 minutos antes. Los filtros de Próximas no cambian estas alertas. En Android, con la app cerrada, necesitas la notificación fija activa.\n\n'
          'El panel consulta las fuentes cada dos minutos: un aviso puede llegar con retraso y depende de que el servicio siga activo. Puede usar datos guardados si las fuentes fallan; la hora de consulta no garantiza que cada cotización sea nueva.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppFlowyTheme.of(context);
    final terms = _normalize(
      _search.text,
    ).split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList();
    final searching = terms.isNotEmpty;
    final topics = _topics.where((topic) {
      final content = _normalize('${topic.$1} ${topic.$2}');
      return terms.every(content.contains);
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Buscar en la guía',
              hintText: 'CPI, inflación, empleo, USD…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey(_search.text),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(12),
            children: [
              if (!searching)
                AfCard(
                  child: Text(
                    'Tu guía de Tradex\nAbre un tema para entender lo que ves en la app. Disponible sin conexión.',
                    style: t.textStyle.body.standard(
                      color: t.textColorScheme.primary,
                    ),
                  ),
                ),
              if (searching)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    topics.isEmpty
                        ? 'No hay temas con esa búsqueda. Prueba con CPI, empleo o dólar.'
                        : '${topics.length} ${topics.length == 1 ? "tema encontrado" : "temas encontrados"}',
                    style: t.textStyle.caption.standard(
                      color: t.textColorScheme.secondary,
                    ),
                  ),
                ),
              if (!searching) const SizedBox(height: 8),
              for (final topic in topics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AfCard(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      key: PageStorageKey('$searching:${topic.$1}'),
                      initiallyExpanded: searching,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        topic.$1,
                        style: t.textStyle.body.enhanced(
                          color: t.textColorScheme.primary,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(
                          topic.$2,
                          style: t.textStyle.body.standard(
                            color: t.textColorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
