# Fase 2 — Navegación adaptable y ajustes personalizados

> Evolución: la vista actual incluye un índice móvil con perfil y grupos, detalles con regreso, edición de perfil y acceso demo. Consulta [Perfil y autenticación](profile-auth.md). El menú superior móvil descrito en la primera versión se sustituyó por ese recorrido.

## Qué se implementó

- **Móvil, menos de 900 px:** barra inferior con Tareas, Buscar, Crear y Ajustes. El drawer queda disponible para los filtros Todas, Pendientes y Completadas.
- **Escritorio, desde 900 px:** barra lateral con destinos y filtros. La barra inferior desaparece.
- **Buscar:** abre la lista con filtro Todas y enfoca el campo. La consulta se conserva al visitar Ajustes; crear una tarea la limpia para mostrar la tarea nueva.
- **Crear:** es una acción, no una pestaña vacía. Abre el formulario desde cualquier sección. Cancelar conserva la sección; crear vuelve a Tareas.
- **Ajustes:** Apariencia, Espacio de trabajo y Acerca de. El menú se coloca arriba en pantallas estrechas y a la izquierda cuando su área dispone de al menos 720 px.

## Opciones con comportamiento real

| Opción | Efecto |
|---|---|
| Sistema / Claro / Oscuro | Cambia `MaterialApp.themeMode` y los tokens de `AppFlowyTheme` |
| Normal / Grande / Muy grande | Multiplica el escalado del sistema por 1, 1.15 o 1.3 |
| Filas compactas | Reduce el padding vertical de las filas |
| Mostrar completadas | Controla si aparecen en Todas y Buscar; Completadas siempre permite consultarlas |
| Nombre del espacio | Actualiza cabecera, barra lateral e inicial del avatar; valida 1–40 caracteres visibles tras `trim` |
| Restablecer preferencias | Restaura tema, escala, densidad, visibilidad y nombre; conserva las tareas |

Las tareas y las preferencias siguen siendo **de sesión**. El gestor de estado no proporciona almacenamiento. La categoría Espacio de trabajo explica este límite en la interfaz.

## Arquitectura: dos responsabilidades, dos Cubit

```text
WorkspaceApp
  └── BlocProvider<SettingsCubit>
        └── MaterialApp
              └── AppFlowyTheme + MediaQuery
                    └── WorkspacePage
                          └── BlocProvider<WorkspaceCubit>
                                └── Vista adaptable
                                      ├── Navegación
                                      └── IndexedStack
                                            ├── Tareas / búsqueda
                                            └── SettingsPage
```

`SettingsCubit` está por encima de la navegación porque sus datos afectan a toda la aplicación. `WorkspaceCubit` continúa siendo responsable de las tareas. Cambiar un tema no crea una lista nueva de tareas.

La sección seleccionada, la categoría de ajustes, el filtro y la consulta son estado de presentación local. Los controladores y el nodo de foco se liberan en `dispose`.

`IndexedStack` mantiene montadas ambas vistas y muestra una de ellas. Permite visitar Ajustes sin perder el campo de búsqueda ni el estado de la pantalla. Es suficiente para estas dos vistas pequeñas; no se añadió un router ni navegadores anidados.

### Ejemplo: cambiar el tema

```text
WorkspaceChoice("Oscuro")
  → SettingsCubit.setTheme(ThemeMode.dark)
  → SettingsState nuevo
  → BlocBuilder en WorkspaceApp
  → MaterialApp.themeMode + AppFlowyTheme
  → consumidores actualizados
```

El acceso rápido de la cabecera usa el mismo Cubit. No hay dos selecciones de tema independientes que puedan desincronizarse.

### Ejemplo: ocultar completadas

```text
WorkspaceToggle
  → SettingsCubit.setShowCompleted(false)
  → la vista escucha SettingsCubit
  → filtra la representación, sin borrar tareas
```

Los contadores siguen mostrando las cantidades reales. El filtro Completadas permite acceder a ellas aunque estén ocultas en la vista general.

## Cómo se construyeron los controles

Archivo para estudiar: `lib/design_system/workspace_controls.dart`.

### `WorkspaceChoice`

```text
Semantics(button, selected)
  └── AFBaseButton: foco, acciones de teclado, hover y pulsación
        └── Row o Column: icono y texto
```

Decide el fondo con `themeSelect` o `contentHover`, y el texto con `action` o `secondary`. Sirve para destinos de navegación, categorías y opciones de tema/tamaño. La presentación vertical se utiliza en la barra inferior.

### `WorkspaceToggle`

```text
Semantics(toggled, label, onTap)
  └── AFBaseButton
        └── Row
              ├── etiqueta y descripción flexibles
              └── AnimatedContainer con indicador circular
```

No es un `Switch` con un color cambiado: el aspecto se compone localmente y reutiliza el comportamiento de `AFBaseButton`. Todo el bloque es pulsable. `Semantics` comunica su estado como interruptor; el indicador visual no duplica el contenido accesible.

El tamaño de texto conserva la función de escalado original del sistema mediante un `TextScaler` compuesto. No sustituye una ampliación accesible del usuario por el tamaño elegido en la app.

## Archivos que conectan la fase

| Archivo | Responsabilidad |
|---|---|
| `lib/main.dart` | Proveedor de ajustes, modo de tema y escala global |
| `lib/settings/application/settings_cubit.dart` | Estado inmutable, opciones válidas y nombre validado |
| `lib/settings/presentation/settings_page.dart` | Categorías, formulario y callbacks |
| `lib/design_system/workspace_controls.dart` | Controles visuales propios construidos por composición |
| `lib/workspace/presentation/workspace_page.dart` | Destino actual, búsqueda, filtros y conservación de vistas |
| `lib/workspace/presentation/workspace_widgets.dart` | Barra inferior, lateral y densidad de tareas |
| `test/settings_cubit_test.dart` | Validación, inmutabilidad y restablecimiento |
| `test/settings_page_test.dart` | Flujos entre pantallas, efectos de ajustes, teclado y escala accesible |

## Relación con AppFlowy

Se consultaron estos archivos del checkout original, dentro de `frontend/appflowy_flutter/lib/`:

- `mobile/presentation/mobile_bottom_navigation_bar.dart`: shell y acciones inferiores, distinguiendo destinos de creación.
- `mobile/presentation/setting/appearance/appearance_setting_group.dart`: ajustes agrupados de apariencia.
- `workspace/presentation/settings/settings_dialog.dart`: menú lateral y contenido por categoría en escritorio.

La composición de esta fase es código educativo local. Reutiliza los tokens y componentes que ya estaban incorporados; no copia las pantallas originales ni sus servicios. Las categorías corresponden a funciones implementadas en esta base.

## Verificación

```bash
flutter analyze
flutter test
flutter build linux --debug
```

Las pruebas incluyen creación desde Ajustes, búsqueda, conservación al cambiar entre móvil/escritorio, tema, densidad, visibilidad, nombre inválido y válido, restablecimiento sin borrar tareas, teclado y pantalla de 320 px con ampliación del sistema y de la app combinadas.

Las capturas se revisaron en una copia temporal web de la app; no se añadió la plataforma web al proyecto principal. Android sigue pendiente de ejecución en emulador o dispositivo.

## Lectura práctica

1. Sigue el callback de `WorkspaceToggle` hasta `emit` y localiza el consumidor del dato.
2. Compara `Semantics` con la decoración: uno comunica el estado a tecnologías de asistencia y el otro lo dibuja.
3. Sigue `WorkspaceChoice` hasta `AFBaseButton` para identificar qué interacción reutiliza y qué diseño define localmente.
4. Comprueba por qué Crear no modifica el destino hasta que el formulario devuelve un título.
5. Cambia de ancho y confirma que los proveedores no están dentro de la rama que alterna la navegación.
