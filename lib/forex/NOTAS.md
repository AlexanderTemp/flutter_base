# Módulo Forex Factory — Fase 1

Noticias de alto impacto (rojas) de Forex Factory dentro de la app, **sin IA,
sin servidor, sin tokens**. Rama: `feature/ff-watch`.

## Qué hace hoy (Fase 1)

- Descarga el **feed oficial de FairEconomy** (`ff_calendar_thisweek.json`), la
  misma fuente que alimenta el calendario de FF.
- Lista las noticias **rojas** de hoy / de la semana con su **forecast** y
  **previo** (pantalla `ForexPage`, accesible desde el botón 📈 de la barra).
- **Pre-aviso** con notificación local ~5 min antes de cada noticia roja
  (mientras la app está en primer plano / escritorio abierto).

## Archivos

| Archivo | Rol |
|---|---|
| `ff_models.dart` | modelos (`FfEvent`, `FfDetail`, `FfHistoryPoint`) — Dart puro |
| `ff_feed_client.dart` | **cliente del feed** (lo que usa la app; funciona desde Dart) |
| `ff_client.dart` | cliente de `/calendar` + detalle — para el **proxy** (fase 2) |
| `ff_analyzer.dart` | motor de reglas alcista/bajista (Usual Effect) — sin IA |
| `ff_notifications.dart` | notificaciones locales (Android/iOS/macOS/Linux) |
| `forex_controller.dart` | estado + pre-avisos en primer plano |
| `forex_page.dart` | UI de la lista |
| `../../tool/ff_demo.dart` | demo de consola: `dart run tool/ff_demo.dart --week` |

## Limitación encontrada (importante)

El cliente HTTP de Dart recibe **403** en `www.forexfactory.com/calendar`
(Cloudflare ficha su huella TLS; `curl` y Python sí pasan). Por eso:

- ✅ La app **sí** lee el **feed** → programación + forecast + previo.
- ❌ La app **no** puede leer `/calendar` → de ahí salen el **valor `actual`**
  y la **regla de interpretación** (`ff_client.dart` + `ff_analyzer.dart` ya
  están listos, pero necesitan ejecutarse desde fuera del móvil).

## Fase 2 (pendiente)

1. **Mini-proxy** (reutiliza `ff_client.dart`/`ff_analyzer.dart` en Python o
   Dart de servidor): sondea `/calendar`, saca el `actual` y el veredicto
   alcista/bajista, y lo expone por REST/WebSocket a la app.
2. **Push** (FCM) para avisar en el móvil con la app cerrada.
3. **Tray icon** de escritorio (`tray_manager` + `window_manager`).

> El veredicto alcista/bajista ya está implementado y probado en
> `ff_analyzer.dart`; solo le falta la fuente del `actual` (el proxy).
