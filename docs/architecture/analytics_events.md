# Analytics events

## Objetivo
Medir activación, publicación, consumo y repetición desde el primer build útil.

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
