# Supabase backend base

## Objetivo

Aterrizar la primera base real del backend del MVP con:

- esquema inicial de tablas
- RLS mínimas
- publicación por slug
- registro básico de eventos analíticos
- estructura de funciones para publicación y analítica

## Estructura

```text
backend/supabase/
├── README.md
├── migrations/
│   └── 20260331_0001_init_schema.sql
├── functions/
│   ├── _shared/
│   │   └── cors.ts
│   ├── ingest_analytics/
│   │   └── index.ts
│   └── publish_project/
│       └── index.ts
└── seed/
    └── seed.sql
```

## Qué crea esta base

### Tablas
- `profiles`
- `projects`
- `play_sessions`
- `generated_assets`
- `analytics_events`
- `feature_entitlements`

### Funciones SQL
- `public.set_updated_at()`
- `public.generate_project_slug(input_title text, fallback_id uuid)`
- `public.publish_project(p_project_id uuid)`
- `public.log_analytics_event(p_event_name text, p_project_id uuid, p_session_id uuid, p_properties jsonb)`

### Índices y restricciones
- unicidad de `publish_slug`
- índices por `owner_id`, `status`, `project_id` y `event_name`
- checks para estados y visibilidad del proyecto

## Principios de implementación

- mantener distinción entre datos del creador, datos públicos publicados y sesiones anónimas
- usar SQL explícito y contratos pequeños
- permitir publicación compartible antes que features sociales avanzadas
- mantener la analítica ligada a `project_id`

## Siguiente iteración recomendada

1. conectar `apps/client_godot/` con `publish_project`
2. añadir ingestión de sesiones completas y cierre de sesión
3. ampliar `seed.sql` con catálogos o flags reales
4. documentar cualquier cambio contractual en `docs/architecture/`
