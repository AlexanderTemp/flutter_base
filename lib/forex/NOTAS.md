# App Forex — standalone, sin backend, sin IA

App dedicada a Forex. **Todo vive en la app** (Dart): nada de servidor, nada de
Python, nada de API keys. Rama: `feature/ff-watch`.

## Pestañas

1. **📅 Próximas** — calendario de noticias con filtros (impacto Alto/Medio/Bajo,
   divisa, Hoy/Semana). Fuente: feed oficial de FairEconomy. Auto-refresco 60 s.
   Pre-avisos con notificación local ~5 min antes.
2. **📰 Noticias** — últimas noticias forex por RSS (FXStreet + Investing.com).
   Auto-refresco 3 min.
3. **🧠 Análisis** — precios cripto en vivo (CoinGecko: BTC/ETH/SOL) + análisis
   por plantillas de las noticias de alto impacto, con su **reacción típica en
   cripto**. Heurística educativa, no consejo financiero.

## Fuentes (todas accesibles desde Dart, verificado)

| Dato | Fuente | Nota |
|---|---|---|
| Calendario + forecast/previo | `nfs.faireconomy.media` (feed oficial) | sin `actual` |
| Noticias | RSS FXStreet + Investing.com | |
| Precios cripto | CoinGecko `simple/price` | con cambio 24 h |

## Limitación conocida (sin backend)

El valor **`actual`** (el dato real cuando sale la noticia) vive en
`forexfactory.com/calendar`, que **Cloudflare bloquea para el cliente HTTP de
Dart** (403; curl/navegador sí pasan). Por eso, **sin backend**:

- El análisis de la pestaña 🧠 es **pre-release / esperado** (forecast vs previo
  + tipo de indicador), no el veredicto post-dato.
- El motor de reglas post-`actual` está en `ff_analyzer.dart` (probado), listo
  por si algún día se decide una fuente que lo permita.

## Archivos

```
main.dart                      entrada (ForexApp + tema)
forex/forex_page.dart          shell con las 3 pestañas
forex/calendar_view.dart       pestaña Próximas
forex/forex_controller.dart    estado + filtros + auto-refresco + pre-avisos
forex/ff_feed_client.dart      feed FairEconomy (lo que usa la app)
forex/ff_models.dart           modelos
forex/ff_notifications.dart    notificaciones locales
forex/news/                    pestaña Noticias (RSS)
forex/crypto/                  precios cripto (CoinGecko)
forex/analysis/                pestaña Análisis (plantillas + reacción cripto)
forex/ff_analyzer.dart         motor de reglas alcista/bajista (post-actual)
```
