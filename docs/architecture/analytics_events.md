# Analytics events

## Objetivo

Medir activación, publicación, consumo y repetición desde el primer build útil.

## Contrato de ingestión oficial

La ingestión oficial del MVP usa `backend/supabase/functions/ingest_analytics/`.

Reglas del contrato actual:

- el endpoint soporta un único evento o un batch de hasta 50 eventos por request
- solo se aceptan los eventos documentados en este archivo
- el endpoint oficial devuelve `analytics_event_id` para requests individuales
- para batch devuelve `ingested` y `analytics_event_ids`
- cualquier evento fuera de allow-list devuelve error `400`
- el campo opcional `occurred_at` puede viajar en el payload y se conserva dentro de `properties`

Endpoint oficial:

- `/functions/v1/ingest_analytics`

Endpoint legado no oficial:

- `/functions/v1/ingest_event`
- no forma parte del rollout oficial de staging
- sus ideas útiles ya deben migrarse al contrato de `ingest_analytics`

## Eventos de creación

### onboarding_started

Props:

- source
- device_class

### signup_completed

Props:

- method
- time_to_complete_seconds

### project_created

Props:

- template_id
- source_screen

### playtest_started

Props:

- project_id
- template_id

### playtest_completed

Props:

- project_id
- duration_seconds
- outcome

### project_published

Props:

- project_id
- template_id
- visibility
- teaser_generated

## Eventos de distribución

### project_link_opened

Props:

- project_id
- referrer
- device_class

### result_shared

Props:

- project_id
- channel
- ending_id

## Eventos de juego

### game_session_started

Props:

- project_id
- entrypoint
- player_type

### objective_seen

Props:

- project_id
- objective_id

### ending_reached

Props:

- project_id
- ending_id
- survived_seconds

### game_session_completed

Props:

- project_id
- completed
- ending_id
- survived_seconds

## Métricas derivadas

- tiempo a primera publicación
- proyectos publicados por usuario
- partidas únicas por proyecto a 7 días
- tasa de apertura de enlace
- porcentaje de sesiones completadas
- porcentaje de jugadores que comparten resultado

## Allow-list vigente

- onboarding_started
- signup_completed
- project_created
- playtest_started
- playtest_completed
- project_published
- project_link_opened
- result_shared
- game_session_started
- objective_seen
- ending_reached
- game_session_completed
