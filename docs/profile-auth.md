# Vista completa de ajustes, perfil y acceso de demostración

## Composición visual

La pantalla móvil de Ajustes presenta una tarjeta de perfil con avatar, nombre y acceso al editor, seguida de grupos de cuenta, personalización, espacio de trabajo e información. Cada fila tiene icono, título, descripción y chevron. Su aspecto se construye localmente con tokens, `AFBaseButton`, contenedores y semántica.

Seleccionar una opción abre su detalle. La flecha y el botón Atrás del sistema vuelven al índice. En escritorio las categorías quedan a la izquierda del detalle. Las listas tienen claves `PageStorageKey` distintas para conservar sus posiciones de desplazamiento.

Referencias del original: `mobile/presentation/home/mobile_home_setting_page.dart` y `workspace/presentation/settings/settings_dialog.dart`, dentro de `frontend/appflowy_flutter/lib/` de AppFlowy.

## Perfil local

`SettingsCubit` incorpora nombre para mostrar, descripción y color del avatar. `SettingsPage` es dueña del borrador y de sus controladores, por encima de las ramas de layout; `ProfileEditor` los recibe y aplica el perfil al guardar. Así el borrador sobrevive a cambios entre escritorio, índice móvil y detalles.

- Nombre: obligatorio, hasta 40 caracteres percibidos por el usuario, después de `trim`.
- Descripción: opcional, hasta 160 caracteres.
- Avatar: cuatro variantes de color construidas con tokens semánticos.
- El perfil se refleja en la tarjeta de ajustes.
- Restablecer preferencias visuales conserva el perfil y las tareas.

El perfil local y la identidad autenticada son datos separados. La sesión demo muestra el correo usado para acceder; no sincroniza el perfil con un servidor.

## Flujo de autenticación preparado

```text
Invitado → Iniciar sesión → SignInPage
  → validación local → AuthCubit.signIn
  → estado de carga → AuthRepository.signIn
      ├── resultado AuthUser → sesión activa y regreso a Ajustes
      └── error → mensaje, sin sesión y con posibilidad de reintento

Sesión activa → Cerrar sesión → AuthRepository.signOut
      ├── éxito → invitado
      └── fallo → conserva la sesión y muestra error
```

`AuthCubit` evita solicitudes simultáneas y no emite si se cierra antes de recibir una respuesta. No almacena la contraseña en el estado ni en disco. `SignInPage` libera sus controladores en `dispose`.

`SignInPage` escucha la transición global a sesión activa mediante `BlocConsumer`. Si sigue siendo la ruta actual, se cierra incluso si la solicitud procedía de un formulario anterior que se cerró y reabrió. Una ruta que ya está cerrándose no intenta cerrar otra pantalla.

Cerrar el formulario permite seguir como invitado. Cerrar sesión no borra las tareas de esta demostración local. Una aplicación con datos privados por usuario debe definir esa separación al incorporar el backend y la persistencia.

## El punto que se sustituye al conectar un backend

```dart
abstract interface class AuthRepository {
  Future<AuthUser> signIn(String email, String password);
  Future<void> signOut();
}
```

`WorkspaceApp` recibe opcionalmente una implementación de `AuthRepository`; por defecto crea `DemoAuthRepository`. Las pruebas inyectan implementaciones controladas para simular demora, rechazo y recuperación. Un adaptador real puede llamar a tu API o proveedor de identidad y traducir sus errores a `AuthException`.

**DemoAuthRepository acepta cualquier correo con formato válido y contraseña no vacía.** No verifica credenciales, no genera tokens y no es una autorización de acceso. La vista indica que se usen datos ficticios.

Para una integración real también habrá que implementar restauración de sesión, expiración/revocación, almacenamiento de credenciales de sesión según la plataforma y autorización en el servidor. El correo y el nombre local no prueban la identidad de nadie.

## Archivos para estudiar

| Archivo | Responsabilidad |
|---|---|
| `lib/main.dart` | Proveedores globales e inyección del repositorio de autenticación |
| `lib/auth/application/auth_cubit.dart` | Contrato, demo, identidad, carga, errores y cierre de sesión |
| `lib/auth/presentation/sign_in_page.dart` | Captura de datos y presentación del flujo |
| `lib/settings/presentation/settings_widgets.dart` | Avatar, tarjeta, grupos y filas personalizados |
| `lib/settings/presentation/profile_editor.dart` | Borrador, validación y guardado del perfil |
| `lib/settings/presentation/settings_page.dart` | Índice, detalles, categorías y acceso a la sesión |

## Comprobaciones

Las pruebas cubren perfil válido e inválido, conservación del perfil al restablecer apariencia, inicio de sesión inválido, carga, fallo del servicio, reintento, cancelación, sesión demo, cierre de sesión, solicitudes duplicadas, respuesta tardía y regreso desde un detalle con Atrás del sistema.

También se mantienen las pruebas de tareas, navegación adaptable, texto ampliado y teclado. Las capturas se tomaron en una copia web temporal; el proyecto principal conserva sus plataformas nativas. Android sigue pendiente de ejecución.

Tareas, perfil, ajustes y sesión demo se mantienen solo durante la ejecución. No se añadieron dependencias para esta ampliación.
