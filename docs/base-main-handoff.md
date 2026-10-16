# Memoria de traspaso: Tradex → base de main

## Objetivo acordado

Conservar lo bueno desarrollado en `feature/ff-watch`, trasladar después a `main` las mejoras reutilizables de estilos, configuración y comportamiento, y preparar esa base antes del fork del usuario. Esta memoria vive en Git para no depender de la conversación.

Estado al registrar: 2026-10-16, rama `feature/ff-watch`, HEAD `8c75d41` más cambios locales modificados y nuevos pendientes de commit. El usuario hará commit y push. Este archivo no afirma que ya se hayan hecho ni que se haya cambiado de rama.

## Diferencia esencial entre las ramas

`main` contiene la aplicación educativa/base de espacio de trabajo, ajustes y acceso demo. La rama Tradex sustituyó su entrada y eliminó pantallas, controladores y pruebas de esa base. Una fusión completa arrastraría esas eliminaciones y convertiría `main` en Tradex.

El traspaso solicitado es selectivo: mejoras de base primero; funciones e identidad de mercados se conservan en la rama/producto. Al llegar a esa fase, volver a comparar ambas ramas y acordar la selección exacta antes de aplicar cambios.

## Inventario para la base reutilizable

| Mejora | Archivos de referencia | Qué llevar a main |
|---|---|---|
| Contraste claro/oscuro y colores semánticos | `packages/appflowy_ui/lib/src/theme/data/appflowy_default/semantic.dart`, `packages/appflowy_ui/script/Semantic.Light Mode.tokens.json`, `Semantic.Dark Mode.tokens.json` | Los ajustes coherentes en fuentes JSON y Dart; revisar todas las pantallas de main con estos colores. No copiar solo el generado. |
| Puente Flutter/AppFlowy | `lib/design_system/theme.dart`, builder de `lib/main.dart` | Mantener un tema consistente también en rutas y diálogos. Comparar lo que main ya tiene para no duplicarlo. |
| Tarjetas, etiquetas y composición compacta | `lib/forex/ui.dart`, `calendar_view.dart`, `news/news_view.dart` | Reutilizar los componentes que sirvan a la base, con nombres y ubicación adecuados. Trasladar el patrón de filtros desplazables y avisos expandibles cuando exista una necesidad real. |
| Carga sin bloquear el arranque | `lib/forex/forex_page.dart`, recursos nativos de splash | Un único splash y estados de carga por sección. Aplicarlo al arranque de main sin sustituir su página inicial por ForexHomePage. |
| Navegación con estado y movimiento accesible | `forex_page.dart`, `widgets/price_bar.dart` | Conservar estado de pestañas, pausar animaciones ocultas y respetar reducción de movimiento. No añadir una cinta de precios a una base sin precios. |
| Ciclo de vida asíncrono | Controladores de `lib/forex/` y pruebas `data_flows_test.dart`, `bob_controller_test.dart` | Evitar peticiones simultáneas, notificaciones tras dispose y respuestas de selecciones antiguas. Aplicar a los controladores equivalentes, sin crear una capa genérica nueva. |
| Persistencia y recuperación honesta | `forex_controller.dart`, `bob/bob_controller.dart`, `data/prefs.dart`, pruebas de recuperación | Guardar fecha de descarga correcta, preservar datos ante fallos y distinguirlos de datos frescos. Corregir los pendientes de caché/guardado antes de convertirlos en patrón de base. |
| Enlaces externos y fechas | `news/news_client.dart`, `news/news_view.dart`, `test/data_flows_test.dart` | Validación de esquema/host y manejo de fallo; fechas con zona horaria. Llevarlo donde main realmente abra enlaces o interprete fechas. |
| Información de app | sección «Acerca de Tradex» en `forex/settings/settings_page.dart` | Patrón de versión, información, desarrollo y licencias. Adaptar nombre y créditos a la base; la lectura actual de pubspec no refleja overrides de versión nativa. |
| Recursos de marca reproducibles | `tool/generate_branding.py`, `assets/branding/`, recursos nativos | Conservar el procedimiento para iconos y splash, parametrizar solo si el fork necesita otra marca. Decidir la identidad de main; no imponer automáticamente Tradex a la plantilla. |
| Compatibilidad nativa | `android/app/build.gradle.kts`, `android/gradle.properties`, entitlements macOS, archivos de registro de plugins | Llevar solo cambios requeridos por las dependencias de main. No copiar servicios, permisos o plugins de Tradex si la base no los usa. Ajustar RAM Gradle al entorno. |
| Accesibilidad, licencias y trazabilidad | `THIRD_PARTY.md`, `LICENSE`, paquete local y pruebas de contraste | Preservar arreglos existentes de zonas táctiles/AFTextField y sus pruebas en main, avisos AGPL y atribuciones. Actualizar el registro de cambios visuales y no atribuir resultados históricos a la nueva entrega. |

## Funcionalidades de Tradex que deben quedar preservadas

Estas piezas son producto terminado o trabajo pendiente de validación, no componentes que deban instalarse automáticamente en una plantilla:

- Próximas: impacto/divisas/hoy-semana, fechas completas, recuperación persistente y recarga al deslizar.
- Noticias: calendario FairEconomy separado de titulares RSS; clasificación original, sin fabricar impacto ni fecha de publicación.
- Análisis: eventos de alto impacto por fecha programada descendente, precios legibles y explicación educativa. Pendiente corregir la confusión entre forecast/previo y sorpresa real.
- Boliviano: TCO vigente del BCB, historial diario descendente, 7/30/50/todos/por fechas, movimientos en centavos y porcentaje, variación del rango y recuperación local.
- Catálogo de 56 monedas y selección persistente con búsqueda; cinta con pausa y reducción de movimiento.
- Guía offline con búsqueda por título y explicación, sin distinguir tildes/mayúsculas y con expansión de resultados.
- Ajustes del panel, moneda destacada, alertas de alto impacto opt-in y adelanto 0/5/15 minutos.
- Notificación nativa Android con «Actualizar», integración del servicio y deduplicación de recordatorios. Pendientes límites de Android y antigüedad de precios.
- Identidad Tradex, iconos multiplataforma, un único splash nativo, «Acerca de» con versión del proyecto y desarrollo Aynicode.

## Decisiones que no deben perderse

- No volver a introducir el splash Flutter ni la espera de ocho segundos.
- No restaurar el RemoteViews personalizado que produjo `BadForegroundServiceNotificationException`.
- No restaurar SelectableText en la guía sin resolver y verificar la aserción `_InactiveElements.remove` reportada.
- No presentar programación económica como resultado publicado: el feed no trae `actual`.
- No convertir precios ausentes en ceros ni porcentajes fabricados.
- No asignar la hora del reintento a una copia guardada antigua.
- Mantener UI compacta y sobria, con palabras claras en español y color reservado a estados/variaciones.
- No llevar eliminaciones de pantallas/pruebas de main por una fusión accidental.
- Las pruebas nuevas están escritas, pero no ejecutadas en esta entrega. No reutilizar como garantía los éxitos antiguos del README.

## Ruta de traspaso cuando el usuario lo solicite

1. Guardar todos los cambios de Tradex, incluidos archivos nuevos, en el commit/push de respaldo. Registrar aquí el hash final o tomarlo del historial cuando se retome.
2. Revisar [la auditoría](tradex-audit-2026-10-16.md) y resolver sus prioridades antes de etiquetar una versión estable.
3. Con el árbol guardado, comparar de nuevo `main` y Tradex y seleccionar las mejoras de base del inventario. Conservar pantallas, controladores y pruebas propias de main.
4. Trasladar cada conjunto completo: código, tokens de origen, recursos, configuración y pruebas aplicables. Adaptar las pruebas de Tradex al contexto de main cuando corresponda.
5. Actualizar README/THIRD_PARTY y registrar qué se trasladó, qué sigue siendo exclusivo de Tradex y qué queda pendiente.
6. Con permiso explícito, verificar main en los temas y plataformas acordados y ejecutar sus pruebas. Después preparar el fork desde la base elegida por el usuario.

## Restricciones del equipo y límites actuales

- No compilar, ejecutar, instalar, abrir emuladores ni correr pruebas que compilen sin autorización explícita. Usar inspección y comprobaciones ligeras.
- Al revisar el disco, `/home` estaba al 100 % mostrado por `df`, con aproximadamente 679 MiB disponibles; `build/` ocupaba 1,6 GiB y `~/.gradle` 15 GiB. Son mediciones puntuales, no instrucciones de borrado. Liberar espacio antes de compilar o si Git vuelve a fallar al escribir.
- No se ha hecho merge, cherry-pick ni transferencia a main desde esta tarea. No hay garantía de entrega continua de alertas en Android moderno.
