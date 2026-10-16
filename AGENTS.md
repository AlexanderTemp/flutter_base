# Restricciones del entorno

- No ejecutar compilaciones, `flutter run`, emuladores ni pruebas que compilen sin una petición explícita del usuario. El equipo comparte RAM con otros procesos.
- Para revisar cambios, usar inspección de archivos y comprobaciones ligeras. No instalar ni ejecutar la app por cuenta propia.

## Continuidad entre ramas

- El inventario de mejoras que el usuario quiere conservar y trasladar selectivamente a `main` está en `docs/base-main-handoff.md`; leerlo antes de ese traspaso.
- Auditoría estática de Tradex y pendientes: `docs/tradex-audit-2026-10-16.md`. Las pruebas nuevas no se han ejecutado en esta entrega.
