# Código y recursos reutilizados de AppFlowy

Origen: https://github.com/AppFlowy-IO/AppFlowy

Commit de referencia: `5cf3a365dec0d59f64bad1ee4bb1050471a39b93`.

- `packages/appflowy_ui/lib/`, `script/`, `pubspec.yaml`, `README.md`, `CHANGELOG.md` y `LICENSE` proceden de `frontend/appflowy_flutter/packages/appflowy_ui/`.
- `assets/icons/*.svg` proceden de `frontend/resources/flowy_icons/20x/`.
- Se conserva el texto de licencia del repositorio original en `LICENSE` y en `packages/appflowy_ui/AGPL-LICENSE`. El `LICENSE` interno del paquete original contiene un marcador TODO, no una licencia permisiva alternativa.

El paquete se incluye como fuente local para que la app no dependa de la carpeta AppFlowy ni de su backend Rust. Los tokens JSON y su generador se conservan junto a los componentes. Las adaptaciones locales se documentan aquí; las actualizaciones no se descargan automáticamente.

La pantalla del espacio de trabajo y su Cubit son código educativo de esta base; no son la aplicación completa ni su editor. Esta entrega usa AGPLv3: al redistribuir un derivado comercial, respeta sus avisos y obligaciones de código fuente.
