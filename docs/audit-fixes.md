# Auditoría Ponytail y correcciones de la base

Fecha: 15 de octubre de 2026.

## Alcance y veredicto

Se revisó la base como aplicación educativa local, para una persona y listas pequeñas, y como punto de partida para nuevos módulos. Se leyeron los flujos de tareas, perfil, ajustes y acceso, los componentes compartidos utilizados, sus pruebas y la configuración Android. Se aplicaron también las guías oficiales de accesibilidad de Flutter.

La auditoría encontró cinco problemas concretos y los reprodujo fuera del repositorio. Esta entrega los corrige y añade pruebas permanentes que exigen el comportamiento correcto.

**Resultado:** base corregida para continuar el desarrollo y reutilizar estos módulos. No constituye una certificación de cualquier aplicación futura: cada funcionalidad y plataforma nueva requiere sus propias verificaciones.

## 1. Borrador del perfil al cambiar de distribución

**Antes:** el editor era dueño de sus controladores y del color seleccionado. Al cambiar entre el layout de escritorio y el índice/detalle móvil, se desmontaba el widget y desaparecía lo escrito sin guardar. Se reprodujo reduciendo la ventana de 1280 a 900 px.

**Corrección:** `SettingsPage` posee los controladores del nombre y la descripción, y el color del borrador. `ProfileEditor` los recibe. El dueño vive por encima de la rama adaptable y libera sus controladores al desmontarse.

El estado guardado continúa en `SettingsCubit`; un borrador no se aplica automáticamente. La prueba edita los tres valores, cambia de distribución, verifica que siguen pendientes y finalmente guarda.

Archivos: `lib/settings/presentation/settings_page.dart`, `profile_editor.dart` y `test/profile_auth_page_test.dart`.

## 2. Zonas pulsables pequeñas

**Antes:** Nueva tarea medía 32 px de alto y los botones de menú/tema 44 × 44. La guía Android pide 48 × 48 y la de iOS 44 × 44.

**Corrección:** `AFBaseButton` aplica restricciones mínimas de 48 × 48 píxeles lógicos en la pieza compartida. No se añadieron parches independientes a cada pantalla. Los campos también tienen altura mínima de 48, después de detectar entradas de 40 px en el acceso.

Son tamaños mínimos, no alturas fijas: el contenido puede crecer al ampliar texto. Como toda restricción Flutter, un padre que obligue a un tamaño menor puede limitarla; hay que comprobar los nuevos usos.

Archivos: `packages/appflowy_ui/lib/src/component/button/base_button/base_button.dart` y `textfield/textfield.dart`.

## 3. Contraste

**Antes:** el botón blanco/azul medía 2.32:1 y la opción Tareas seleccionada 2.91:1, frente al mínimo 4.5:1 exigido para esos textos. Los textos secundarios de la barra también quedaban ligeramente por debajo.

**Corrección:** se editaron los JSON semánticos, no solo los valores Dart generados:

| Rol | Cambio |
|---|---|
| `Fill.theme-thick`, ambos temas | `Blue.500` → `Blue.800` |
| `Fill.theme-thick-hover`, ambos temas | `Blue.600` → `Blue.900` |
| `Text.action`, claro | `Blue.600` → `Blue.800` |
| `Text.action-hover`, claro | `Blue.700` → `Blue.900` |
| `Text.secondary`, claro | `Neutral.600` → `Neutral.700` |
| `Text.tertiary`, claro | `Neutral.500` → `Neutral.700` |
| `Text.tertiary`, oscuro | `Neutral.600` → `Neutral.500` |

Se ejecutó `dart run script/generate_theme.dart` dentro de `packages/appflowy_ui`. La paleta primitiva sigue siendo la original; cambió la asignación de roles para mejorar legibilidad. Las capturas antiguas representan el diseño anterior a estos ajustes.

## 4. Acceso reabierto con una respuesta pendiente

**Antes:** `_submit` cerraba solo el formulario que había enviado la solicitud. Si se cerraba y reabría antes de que llegara el éxito, el formulario nuevo quedaba abierto aunque ya hubiera sesión.

**Corrección:** `BlocConsumer` escucha la transición global de invitado a usuario. El formulario actual se cierra al recibirla. Se comprueba `ModalRoute.isCurrent` para que una ruta que está saliendo no cierre otra por accidente.

`AuthCubit` sigue bloqueando solicitudes simultáneas. La prueba usa un repositorio controlado: envía, cierra, reabre, completa la respuesta y exige volver a Ajustes con la sesión visible y una sola solicitud al servicio.

Archivo: `lib/auth/presentation/sign_in_page.dart`.

## 5. Controlador de AFTextField

**Antes:** el controlador efectivo era `late final` y se asignaba solo en `initState`. Reconstruir el campo con otro controlador conservaba el anterior.

**Corrección:** `didUpdateWidget` elimina el listener antiguo y adopta el controlador nuevo. Si deja de recibir uno externo, crea uno interno copiando el valor completo, incluida la selección. Solo libera controladores creados por el campo; también sincroniza cambios de `obscureText`.

La prueba recorre interno → externo A → externo B → interno. Verifica cambio de instancia, valor/selección, listeners, ocultación y propiedad de los recursos.

Archivos: `packages/appflowy_ui/lib/src/component/textfield/textfield.dart` y `test/textfield_lifecycle_test.dart`.

## Verificación final

- `flutter analyze`: sin incidencias.
- `flutter test`: **22 pruebas aprobadas**, frente a 17 antes de la corrección.
- `test/accessibility_test.dart`: áreas táctiles Android/iOS, etiquetas y contraste en tareas, índice de ajustes, apariencia y acceso; temas claro y oscuro.
- `flutter build apk --debug`: compilación correcta; salida `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build linux --debug`: compilación correcta; salida `build/linux/x64/debug/bundle/flutter_workspace`.

Las pruebas de accesibilidad verifican las pantallas/estados recorridos. No sustituyen una revisión completa con lector de pantalla o dispositivos físicos.

## Lo que continúa siendo deliberadamente demo

Datos, perfil, preferencias y sesión siguen en memoria. `DemoAuthRepository` no verifica credenciales y debe sustituirse para autenticar de verdad. Android se compiló, pero sigue pendiente su ejecución en emulador o dispositivo. No se verificaron compilaciones de distribución ni iOS/macOS/Windows.

Las modificaciones del paquete incorporado están registradas en `THIRD_PARTY.md`; hay que revisarlas al actualizarlo desde AppFlowy. No se añadieron dependencias.
