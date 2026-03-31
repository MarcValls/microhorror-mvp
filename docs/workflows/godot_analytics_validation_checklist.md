# Godot Analytics Validation Checklist

## Objetivo

Validar manualmente que el cliente Godot del MVP emite los eventos analíticos correctos para playtest y sesión real sin duplicaciones ni contaminación entre flujos.

Esta checklist se centra en los eventos documentados en `docs/architecture/analytics_events.md` y en la implementación actual del cliente bajo `apps/client_godot/`.

## Alcance

Incluye:

- validación de `playtest_started`
- validación de `playtest_completed`
- validación de `game_session_started`
- validación de `ending_reached`
- validación de `game_session_completed`
- comprobación de payloads básicos
- comprobación de no duplicación

Excluye:

- validación automática por tests
- revisión de métricas agregadas en producto
- despliegue de Supabase

## Archivos relevantes

- `/apps/client_godot/project.godot`
- `/apps/client_godot/scripts/autoloads/backend_client.gd`
- `/apps/client_godot/scripts/autoloads/analytics_tracker.gd`
- `/apps/client_godot/scripts/autoloads/event_bus.gd`
- `/apps/client_godot/scripts/runtime/runtime_session.gd`
- `/apps/client_godot/scripts/editor/project_editor.gd`
- `/docs/architecture/analytics_events.md`

## Preparación

1. Abre el proyecto `apps/client_godot/project.godot` en Godot 4.5.
2. Asegúrate de que `SUPABASE_URL` y `SUPABASE_ANON_KEY` están configuradas para el cliente.
3. Abre el panel de salida de Godot y, si vas a verificar red, prepara también el monitor HTTP o el backend remoto donde ingiere `ingest_analytics`.
4. Parte de un proyecto activo válido para que el runtime tenga `project_id` y `template_id`.

## Caso A — Playtest completado

1. Entra al editor del proyecto.
2. Pulsa el CTA de playtest.
3. Completa la sesión hasta alcanzar un final.

Resultado esperado:

- se emite `playtest_started` una vez
- se emite `playtest_completed` una vez
- `playtest_completed` lleva `outcome` y `duration_seconds > 0`
- no se emiten `game_session_started`, `ending_reached` ni `game_session_completed`
- al salir de la escena no aparece un segundo `playtest_completed`

## Caso B — Playtest cancelado

1. Entra al editor del proyecto.
2. Pulsa el CTA de playtest.
3. Abandona la escena runtime antes de alcanzar un final.

Resultado esperado:

- se emite `playtest_started` una vez
- se emite `playtest_completed` una vez con `outcome = cancelled`
- `duration_seconds` refleja el tiempo real transcurrido
- no se emiten `game_session_started`, `ending_reached` ni `game_session_completed`

## Caso C — Sesión real completada

1. Inicia una sesión por el flujo jugable normal.
2. Llega a un final de tipo `success`.

Resultado esperado:

- se emite `game_session_started` una vez
- se emite `ending_reached` una vez
- se emite `game_session_completed` una vez
- no se emiten `playtest_started` ni `playtest_completed`
- `ending_reached` incluye `project_id`, `ending_id` y `survived_seconds`
- `game_session_completed` incluye `project_id`, `completed = true`, `ending_id` y `survived_seconds`

## Caso D — Sesión real fallida

1. Inicia una sesión por el flujo jugable normal.
2. Llega a un final de tipo `failure`.

Resultado esperado:

- se emite `game_session_started` una vez
- se emite `ending_reached` una vez
- se emite `game_session_completed` una vez
- `game_session_completed` lleva `completed = false`
- `ending_id` y `survived_seconds` siguen presentes

## Verificaciones transversales

### No duplicación

En cada uno de los casos anteriores:

- no deben existir dos cierres analíticos iguales para la misma ejecución
- un playtest completado no debe generar después un cierre `cancelled`
- una sesión real no debe disparar eventos de playtest

### Contrato de payload

Contrasta la salida con `docs/architecture/analytics_events.md`.

Debe cumplirse:

- `playtest_started` incluye `template_id`
- `playtest_completed` incluye `outcome` y `duration_seconds`
- `ending_reached` incluye `ending_id` y `survived_seconds`
- `game_session_completed` incluye `completed`, `ending_id` y `survived_seconds`

### Backend

Si el backend está disponible:

- las llamadas a `/functions/v1/ingest_analytics` responden sin `400`
- los nombres de evento coinciden con la allow-list vigente

## Criterios de aceptación

- [ ] Playtest completado registra inicio y cierre una sola vez
- [ ] Playtest cancelado registra cierre `cancelled` una sola vez
- [ ] Sesión real exitosa registra inicio, final alcanzado y cierre una sola vez
- [ ] Sesión real fallida registra inicio, final alcanzado y cierre una sola vez
- [ ] Los payloads mínimos coinciden con la documentación
- [ ] No se observa contaminación entre playtest y sesión real

## Qué hacer si falla

- Si hay duplicación, revisar `apps/client_godot/scripts/runtime/runtime_session.gd` y `apps/client_godot/scripts/autoloads/analytics_tracker.gd`.
- Si falta contexto en el payload, revisar `apps/client_godot/scripts/autoloads/event_bus.gd` y los emitters del runtime.
- Si el backend rechaza eventos válidos, revisar `backend/supabase/functions/ingest_analytics/index.ts` y `docs/architecture/analytics_events.md`.
