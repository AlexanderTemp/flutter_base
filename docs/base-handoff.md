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
| Acerca de | Versión tomada del proyecto, crédito de desarrollo, información y acceso a licencias. No hay una segunda versión escrita a mano en Ajustes. | `lib/app_info.dart`, `pubspec.yaml`, `lib/settings/presentation/settings_page.dart`. |
| Ciclo de vida | El acceso demo rechaza operaciones nuevas después de cerrar el Cubit; conserva sus controles existentes de concurrencia y respuestas tardías. | `lib/auth/application/auth_cubit.dart`. |
| Android | Kotlin integrado coherente con AGP 9 y el bloque `kotlin` existente; límites de Gradle de 2 GiB de heap, 1 GiB de metaspace y dos workers. Son límites del proceso de Gradle, no del consumo total de una compilación. | `android/gradle.properties`. |
| Continuidad | Instrucciones de entorno, alcance de main y esta guía versionadas. Nuevas regresiones para contraste, búsqueda, movimiento, páginas ocultas, Acerca de y Cubit cerrado. | `AGENTS.md`, `test/base_improvements_test.dart`, pruebas de ajustes y autenticación. |

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
4. **Iconos y splash:** sustituir los iconos de plantilla en los recursos de cada plataforma y el splash nativo. Mantener una fuente editable y un procedimiento reproducible si el nuevo producto necesita marca propia. No añadir otra pantalla de espera Flutter.
5. **Diseño:** reutilizar componentes de `lib/design_system/` y AppFlowy antes de crear otros. Mantener tokens de origen y generados sincronizados; revisar claro, oscuro, texto ampliado, teclado y estados vacíos/error.
6. **Datos reales:** las tareas, perfil y preferencias actuales son de sesión. Implementar persistencia con fecha de última descarga correcta y estados de carga/error/datos guardados donde el producto la requiera; conservar selección y datos ante fallos. No usar la hora del intento como fecha de un dato antiguo.
7. **Acceso real:** reemplazar `DemoAuthRepository` por el servicio del nuevo producto. El demo no verifica credenciales ni protege datos. Mantener validación, errores y controles de concurrencia/cierre.
8. **Dependencias y permisos:** añadir únicamente los que use el nuevo producto. En macOS, habilitar salida de red en los entitlements de debug y release cuando realmente se añadan consultas de red. No hay servicios de mercados ni permisos de notificación en esta base.
9. **Versión:** Acerca de lee la versión del pubspec incluido como recurso. Si el proceso de publicación sobrescribe nombre/número de compilación, sustituir esa lectura por metadatos nativos para reflejar el binario instalado.
10. **Verificación:** con autorización para compilar, resolver dependencias de main con `flutter pub get`, ejecutar análisis y pruebas, y revisar la plataforma elegida. Después de cambiar de rama, los artefactos locales pueden seguir correspondiendo a las dependencias de Tradex hasta regenerarlos.

## Alcance y pendientes

No se trasladaron el shell Forex, notificaciones, APIs, cronómetros de consulta, cachés de mercados, cotizaciones BOB/cripto, noticias, textos financieros ni marca Tradex. Esas funciones no tienen un consumidor en la base y permanecen preservadas en `feature/ff-watch`.

La guía financiera y el generador de iconos de Tradex contienen contenido/marca específicos. Se conservaron sus patrones aplicables (búsqueda, movimiento accesible, identidad, licencias y arranque) sin añadir módulos sin uso a main. La base ya tiene sus propios controles y ayuda; no se duplicaron con wrappers de Tradex.

Los arreglos pendientes de la auditoría de Tradex deben resolverse en esa rama; no son dependencias de main. No se introdujo almacenamiento ni backend nuevos para ampliar artificialmente la plantilla.

Verificación de este traspaso: inspección, formato Dart y comprobaciones ligeras. No se compiló, instaló, ejecutó la app ni se corrieron pruebas. Las pruebas nuevas quedan escritas para la siguiente validación autorizada; las comprobaciones antiguas del README no validan estos cambios.

## Licencia

Conservar `LICENSE`, `THIRD_PARTY.md` y avisos del paquete local. El sistema visual reutilizado está bajo AGPLv3; un fork no cambia esas condiciones. El crédito del nuevo producto se adapta manteniendo las atribuciones correspondientes.
