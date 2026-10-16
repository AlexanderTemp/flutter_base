# Código y recursos reutilizados de AppFlowy

Origen: https://github.com/AppFlowy-IO/AppFlowy

Commit de referencia: `5cf3a365dec0d59f64bad1ee4bb1050471a39b93`.

- `packages/appflowy_ui/lib/`, `script/`, `pubspec.yaml`, `README.md`, `CHANGELOG.md` y `LICENSE` proceden de `frontend/appflowy_flutter/packages/appflowy_ui/`.
- `assets/icons/*.svg` proceden de `frontend/resources/flowy_icons/20x/`.
- Se conserva el texto de licencia del repositorio original en `LICENSE` y en `packages/appflowy_ui/AGPL-LICENSE`. El `LICENSE` interno del paquete original contiene un marcador TODO, no una licencia permisiva alternativa.

El paquete se incluye como fuente local para que la app no dependa de la carpeta AppFlowy ni de su backend Rust. Los tokens JSON y su generador se conservan junto a los componentes. Las adaptaciones locales se documentan aquí; las actualizaciones no se descargan automáticamente.

## Adaptaciones locales después de la auditoría (2026-10-15)

- `AFBaseButton` incorpora restricciones mínimas de 48 × 48 píxeles lógicos para las zonas pulsables, respetando las restricciones que imponga su padre.
- `AFTextField` cambia de controlador en `didUpdateWidget`, gestiona listeners y propiedad del recurso, conserva el valor al pasar a un controlador interno y sincroniza cambios de `obscureText`. La decoración de entrada tiene altura mínima de 48 píxeles lógicos.
- Los JSON semánticos claro/oscuro cambian el relleno de acción a `Blue.800` y hover a `Blue.900`. En claro, el texto de acción usa esos tonos y el secundario/terciario usa `Neutral.700`; en oscuro, el terciario usa `Neutral.500`. Se regeneraron los archivos del tema con el generador original.
- Los colores primitivos no cambiaron. La regeneración solo actualiza la fecha del encabezado de `primitive.dart`.

Estas adaptaciones se verifican en las pruebas de accesibilidad y ciclo de vida del proyecto raíz. Deben conservarse o revisarse al actualizar el paquete desde el original.

## Contraste semántico reutilizado en la base (2026-10-16)

- En claro, texto informativo `Blue.800/900` y advertencias `Orange.800/900`.
- En oscuro, texto de éxito `Green.400/300`, advertencias `Orange.300/200` y error `Red.300/200`; fondos informativos `Blue.1000/900` y de advertencia `Orange.1000/900`.
- Se trasladaron juntos los dos JSON semánticos de origen y `semantic.dart` desde `feature/ff-watch` (`06b0135`), sin cambiar los colores primitivos.
- Se añadieron regresiones de contraste en `test/base_improvements_test.dart`. Su ejecución y la revisión visual de los cambios actuales están pendientes; las comprobaciones históricas no se aplican automáticamente a este traspaso.

## Interacción de botones compartidos (2026-10-16)

- `AFBaseButton` no solicita foco cuando está deshabilitado o no tiene acción, comunica su estado habilitado mediante semántica y hace pulsable toda su superficie, incluido el padding.
- El contenido de `AFBaseButton` se centra dentro del padding, manteniendo el tamaño intrínseco. La altura mínima táctil o una altura adicional del padre ya no deja las etiquetas pegadas arriba. La regresión cubre botones rellenos, de contorno y fantasma en todos sus tamaños y con texto ampliado.
- El cambio se aplica a botones rellenos, de contorno, fantasma y sus consumidores. La regresión de interacción y teclado está en `test/button_theme_test.dart`, pendiente de ejecución autorizada.

La pantalla del espacio de trabajo y su Cubit son código educativo de esta base; no son la aplicación completa ni su editor. Esta entrega usa AGPLv3: al redistribuir un derivado comercial, respeta sus avisos y obligaciones de código fuente.
