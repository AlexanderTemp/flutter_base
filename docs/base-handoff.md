# Base Flutter para nuevos forks

## Estado de este traspaso

Se trasladaron selectivamente mejoras de `feature/ff-watch` (Tradex, commit `06b0135`) a la base de `main` (punto de partida `982df1a`). La aplicación de tareas, navegación adaptable, perfil, ajustes y acceso demo de main se conserva. Las funciones de mercados y sus dependencias permanecen en la rama de producto.

## Mejoras incorporadas

| Área | Mejora | Dónde se personaliza |
|---|---|---|
| Colores | Mejor contraste de información y advertencias en claro; fondos oscuros de avisos y texto de éxito/error/advertencia legible en oscuro. Se trasladaron tanto los JSON como Dart. | `packages/appflowy_ui/script/Semantic.*.tokens.json` y `lib/src/theme/data/appflowy_default/semantic.dart` dentro del paquete. |
| Búsqueda | Coincidencias sin distinguir mayúsculas ni tildes españolas, botón para limpiar y conservación de tareas al buscar. | `lib/workspace/presentation/workspace_page.dart`. |
| Movimiento | Los interruptores respetan reducción de movimiento/navegación accesible. Las páginas inactivas del IndexedStack tienen sus tickers deshabilitados. | `lib/design_system/workspace_controls.dart` y `workspace_page.dart`. |
| Identidad | Nombre y desarrollador compartidos en Flutter, nombre visible coherente en los lanzadores/ventanas nativas. | `lib/app_info.dart` y archivos nativos indicados abajo. |
| Acerca de | Versión instalada del APK en Android, versión del proyecto en otras plataformas, crédito AyniCode, entorno development/production, modo debug/profile/release e información y licencias. | `lib/app_info.dart`, `pubspec.yaml`, `lib/settings/presentation/settings_page.dart`, `android/app/src/main/kotlin/com/example/flutter_workspace/MainActivity.kt`. |
| Ciclo de vida | El acceso demo rechaza operaciones nuevas después de cerrar el Cubit; conserva sus controles existentes de concurrencia y respuestas tardías. | `lib/auth/application/auth_cubit.dart`. |
| Android | Kotlin integrado coherente con AGP 9 y el bloque `kotlin` existente; límites de Gradle de 2 GiB de heap, 1 GiB de metaspace y dos workers. Son límites del proceso de Gradle, no del consumo total de una compilación. | `android/gradle.properties`. |
| Continuidad | Instrucciones de entorno, alcance de main y esta guía versionadas. Nuevas regresiones para contraste, búsqueda, movimiento, páginas ocultas, Acerca de y Cubit cerrado. | `AGENTS.md`, `test/base_improvements_test.dart`, pruebas de ajustes y autenticación. |
| Cabecera | Ajustes en un botón superior junto al cambio de tema; barra inferior centrada en Tareas, Buscar y Crear, conservando navegación y borradores. | `lib/workspace/presentation/workspace_page.dart` y `workspace_widgets.dart`. |
| Tema integral | Controles Material alineados con los colores AppFlowy y barras de estado/navegación con iconos apropiados al tema de la app. No modifica la preferencia global del teléfono. | `lib/design_system/theme.dart`, `lib/main.dart`. |
| Marca | Nombre Flutter Base en todas las plataformas, icono propio (adaptativo y monocromo en Android), splash nativo claro/oscuro con el fondo del tema y logo reutilizable. | `assets/branding/`, `pubspec.yaml`, `lib/design_system/app_logo.dart`, recursos nativos de cada plataforma. |
| Botones | Superficie completa pulsable; botones deshabilitados o sin acción fuera del foco de teclado y con estado semántico explícito. | `packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart`, `test/button_theme_test.dart`. |

## Reutilización concreta de la implementación Tradex

Referencia de origen: `feature/ff-watch`, commit `06b0135`. Esta tabla identifica
el código reutilizado y su consumidor real en la base, no solamente una idea visual.

| Implementación de origen | Implementación/consumidor en main | Adaptación necesaria |
|---|---|---|
| `lib/forex/ui.dart`: `AfCard` | `lib/design_system/surfaces.dart`; usado por `SettingsGroup` en `settings_widgets.dart` | Se conserva superficie, borde, radio y API. Se omite el recorte para que los botones hijos mantengan visible su anillo de foco. Reemplaza la decoración repetida de grupos de ajustes. |
| `lib/forex/ui.dart`: `AfPill` | `lib/design_system/surfaces.dart`; usado por Acerca de para entorno y modo de compilación | Se conserva la implementación con tokens; el contenido pasa a ser metadata general. |
| `lib/forex/forex_page.dart`: acciones de cabecera | `IconButton` de tema y ajustes en `workspace_page.dart` | Mismos controles Flutter, iconos y tooltips. Ajustes activa la página conservada de la base en lugar de crear una ruta que descarte sus borradores. |
| `lib/forex/guide/guide_view.dart`: normalización de búsqueda | `_normalizeSearch` de `workspace_page.dart` | Misma conversión de mayúsculas y vocales acentuadas, aplicada a las tareas que sí existen en main. |
| `lib/main.dart` y `lib/design_system/theme.dart`: puente AppFlowy/Material | Builder de `WorkspaceApp` y `workspaceTheme` | Se conserva el puente y los proveedores de la base. La sincronización explícita de barras del sistema y colores Material amplía ese mismo punto compartido. |
| JSON semánticos y `semantic.dart` | Mismos tres archivos en main | Trasladados juntos desde el commit de origen, sin una paleta alternativa. |
| `lib/forex/forex_page.dart`: `TickerMode` alrededor de contenido oculto | Páginas de tareas y ajustes en el `IndexedStack` de main | Aplicado a sus dos páginas, conservando el estado de navegación propio de la base. |
| Acerca de en `lib/forex/settings/settings_page.dart` | Acerca de de la base y `AppInfo` | Se reutiliza lectura de versión del pubspec y la información de desarrollo/licencias. Se añade la versión nativa Android y la flag de entorno solicitadas después. |

Las flags development/production y el canal Android de versión son mejoras nuevas
solicitadas para esta base; no existían en Tradex en el commit de referencia.
Los componentes compartidos se mantienen en `lib/design_system/`, sin importar
archivos de dominio Forex para usarlos.

## Mejoras que main ya tenía y se conservaron

- Paquete AppFlowy local, puente de tema para Flutter y diálogos, tokens, componentes y licencias.
- Zonas táctiles mínimas, navegación con teclado, semántica y adaptación móvil/escritorio.
- Ampliación de texto del sistema combinada con la preferencia de la app.
- Perfil editable con borrador conservado al redimensionar; AFTextField con ciclo de vida de controlador corregido.
- Tareas y ajustes separados en Cubits; navegación que conserva estado.
- Validación y errores en formularios; bloqueo de acceso simultáneo y protección ante respuesta posterior al cierre.
- Arranque directo con splash nativo, sin splash Flutter ni temporizador de entrada.
- Pruebas existentes de la base y documentación de arquitectura.

## Al crear otro proyecto desde esta base

1. **Identidad Flutter:** editar `AppInfo.name` y `AppInfo.developer` en `lib/app_info.dart`, descripción y versión en `pubspec.yaml`, y el nombre inicial de espacio/perfil en `SettingsState` si corresponde. `name: flutter_workspace` es el nombre técnico del paquete; si se cambia, actualizar también sus imports y pruebas.
2. **Identidad nativa:** adaptar `android:label` en `android/app/src/main/AndroidManifest.xml`, nombres en `ios/Runner/Info.plist` y `macos/Runner/Info.plist`, título en `macos/Runner/MainFlutterWindow.swift`, títulos de `linux/runner/my_application.cc`, `windows/runner/main.cpp` y metadatos de `windows/runner/Runner.rc`. Flutter y los lanzadores nativos no comparten automáticamente una constante.
3. **Identificadores y firma:** elegir applicationId/bundle identifiers propios y una firma release estable antes de distribuir actualizaciones. La base conserva los identificadores de ejemplo y la firma debug del template. No versionar claves ni credenciales; Android ya las excluye en `.gitignore`.
4. **Iconos y splash:** reemplazar los PNG de `assets/branding/` conservando nombres y proporciones, y ejecutar `dart run flutter_launcher_icons` y `dart run flutter_native_splash:create`. La configuración está en `pubspec.yaml`; ajustar allí los colores del splash si cambia el fondo del tema. No añadir otra pantalla de espera Flutter.

   | Fuente | Uso | Requisitos |
   |---|---|---|
   | `icon.png` | Icono iOS, macOS, Windows y Android heredado | 1024×1024, opaco, a sangre (cada sistema aplica su máscara). |
   | `icon_background.png` / `icon_foreground.png` | Icono adaptativo y monocromo de Android 8+/13+ | 1024×1024; el glifo del frente ocupa como máximo el 66 % central y es transparente alrededor. |
   | `splash.png` | Splash claro/oscuro de iOS y Android anterior a 12 | 768×768 con transparencia; se muestra centrado. |
   | `splash_android12.png` | Splash de Android 12+ sobre círculo de color | 1152×1152; el glifo cabe en el círculo central de 768 px. |
   | `logo.png` | Logo dentro de la app (`AppLogo`, `AppInfo.logoAsset`) | 512×512; único archivo de marca empaquetado como asset. |

   Linux usa `logo.png` del bundle como icono de ventana desde `linux/runner/my_application.cc`.
5. **Diseño:** reutilizar componentes de `lib/design_system/` y AppFlowy antes de crear otros. Mantener tokens de origen y generados sincronizados; revisar claro, oscuro, texto ampliado, teclado y estados vacíos/error.
6. **Datos reales:** las tareas, perfil y preferencias actuales son de sesión. Implementar persistencia con fecha de última descarga correcta y estados de carga/error/datos guardados donde el producto la requiera; conservar selección y datos ante fallos. No usar la hora del intento como fecha de un dato antiguo.
7. **Acceso real:** reemplazar `DemoAuthRepository` por el servicio del nuevo producto. El demo no verifica credenciales ni protege datos. Mantener validación, errores y controles de concurrencia/cierre.
8. **Dependencias y permisos:** añadir únicamente los que use el nuevo producto. En macOS, habilitar salida de red en los entitlements de debug y release cuando realmente se añadan consultas de red. No hay servicios de mercados ni permisos de notificación en esta base.
9. **Versión:** Android lee nombre y código de versión del APK instalado, incluidos overrides de compilación. El pubspec incluido como recurso es el respaldo y la fuente de las otras plataformas; para overrides fuera de Android, añadir lectura de metadatos nativos allí.
10. **Verificación:** con autorización para compilar, resolver dependencias de main con `flutter pub get`, ejecutar análisis y pruebas, y revisar la plataforma elegida. Después de cambiar de rama, los artefactos locales pueden seguir correspondiendo a las dependencias de Tradex hasta regenerarlos.

## Alcance y pendientes

### Flag de entorno

El entorno se define en `lib/app_environment.dart` y se elige al compilar con
`APP_ENV`. Es independiente del modo debug/profile/release: una APK release no se
marca automáticamente como producción. Un valor desconocido detiene el arranque
para que un error tipográfico no se distribuya como otro entorno.

| `APP_ENV` | Uso | Insignia (`EnvironmentBadge`) |
|---|---|---|
| `development` (por defecto) | Trabajo local | **Modo desarrollo** |
| `test` | APK para testers/QA | **Versión de pruebas · puede contener errores**, con color de advertencia |
| `production` | Publicación | Ninguna |

La insignia flota centrada en la zona inferior, por encima de rutas y diálogos, sin
reservar espacio ni interceptar pulsaciones. Ajustes → Acerca de muestra el entorno
y el modo de compilación.

```bash
flutter run                                                # development
flutter build apk --release --dart-define=APP_ENV=test     # testers
flutter build apk --release --dart-define=APP_ENV=production
```

En Android Studio, añadir `--dart-define=APP_ENV=...` en **Additional run args**.
Para varios valores por entorno (URL de API, claves públicas), usar
`--dart-define-from-file=env/<entorno>.json` sin versionar secretos. Si testers y
usuarios necesitan instalar ambas versiones a la vez, añadir *flavors* nativos con
`applicationIdSuffix` y nombre propio; no se incluyen en la base para no complicarla.
Los comandos anteriores son instrucciones para el usuario; no se han ejecutado en esta tarea.
Esta flag identifica el entorno; no añade por sí sola backend ni firma release.

No se trasladaron el shell Forex, notificaciones, APIs, cronómetros de consulta, cachés de mercados, cotizaciones BOB/cripto, noticias, textos financieros ni marca Tradex. Esas funciones no tienen un consumidor en la base y permanecen preservadas en `feature/ff-watch`.

La guía financiera y el generador de iconos de Tradex contienen contenido/marca específicos. Se reutilizaron las implementaciones aplicables (búsqueda, tarjetas, etiquetas, acciones superiores, movimiento accesible, identidad y arranque). Las tarjetas y etiquetas de Tradex se extrajeron al sistema visual general y tienen consumidores reales en main; los controles ya existentes se conservan donde corresponden.

Los arreglos pendientes de la auditoría de Tradex deben resolverse en esa rama; no son dependencias de main. No se introdujo almacenamiento ni backend nuevos para ampliar artificialmente la plantilla.

Verificación de este traspaso: inspección, formato Dart y comprobaciones ligeras. No se compiló, instaló, ejecutó la app ni se corrieron pruebas. Las pruebas nuevas quedan escritas para la siguiente validación autorizada; las comprobaciones antiguas del README no validan estos cambios.

## Licencia

Conservar `LICENSE`, `THIRD_PARTY.md` y avisos del paquete local. El sistema visual reutilizado está bajo AGPLv3; un fork no cambia esas condiciones. El crédito del nuevo producto se adapta manteniendo las atribuciones correspondientes.
