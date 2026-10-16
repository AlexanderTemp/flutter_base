# Restricciones del entorno

- No ejecutar compilaciones, `flutter run`, emuladores ni pruebas que compilen sin una petición explícita del usuario. El equipo comparte RAM con otros procesos.
- Para revisar cambios, usar inspección de archivos y comprobaciones ligeras. No instalar ni ejecutar la app por cuenta propia.

# Propósito de esta rama

- `main` es una base Flutter general para futuros forks. Conservar sus pantallas, ajustes, tareas de demostración y acceso demo.
- El registro de mejoras reutilizadas y pasos para crear otro producto está en `docs/base-handoff.md`.
- Tradex y sus funciones de mercados viven en `feature/ff-watch`. No fusionar la rama completa ni introducir su marca, fuentes, permisos o servicios en esta base.
- Mantener sincronizados los tokens JSON de `packages/appflowy_ui/script/` y su representación Dart. Preservar `LICENSE`, `THIRD_PARTY.md` y los arreglos de accesibilidad del paquete local.
