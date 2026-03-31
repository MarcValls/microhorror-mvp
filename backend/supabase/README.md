# Supabase backend base

## Objetivo

Aterrizar la primera base real del backend del MVP con:

- esquema inicial de tablas
- RLS mínimas
- publicación por slug
- registro básico de eventos analíticos
- estructura de funciones para publicación y analítica
- scripts de despliegue y validación remota

## Estructura

```text
backend/supabase/
├── README.md
├── .env.example
├── migrations/
│   └── 20260331_0001_init_schema.sql
├── functions/
│   ├── _shared/
│   │   └── cors.ts
│   ├── import_map.json
│   ├── ingest_analytics/
│   │   └── index.ts
│   └── publish_project/
│       └── index.ts
├── scripts/
│   ├── deploy_remote.sh
│   └── validate_remote.sh
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

## Quickstart recomendado

### 1. Copiar variables de entorno

```bash
cp "backend/supabase/.env.example" "backend/supabase/.env"
```

### 2. Editar `backend/supabase/.env`

Rellena como mínimo:

- `SUPABASE_PROJECT_REF`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Para validación funcional completa añade también:

- `SUPABASE_USER_ACCESS_TOKEN`

### 3. Lanzar despliegue automático

```bash
bash "backend/supabase/scripts/deploy_remote.sh"
```

Si `DEPLOY_RUN_VALIDATION="1"` en `backend/supabase/.env`, el script ejecutará también la validación remota al final.

## Scripts disponibles

### `backend/supabase/scripts/deploy_remote.sh`

Automatiza:

- verificación de herramientas
- login de Supabase CLI
- link al proyecto remoto
- aplicación de migración
- carga de seed
- publicación de secretos
- despliegue de edge functions
- validación opcional

### `backend/supabase/scripts/validate_remote.sh`

Automatiza:

- validación de tablas
- validación de funciones SQL
- validación de seed
- prueba de `ingest_analytics`
- validación funcional de `publish_project` si existe `SUPABASE_USER_ACCESS_TOKEN`

## Principios de implementación

- mantener distinción entre datos del creador, datos públicos publicados y sesiones anónimas
- usar SQL explícito y contratos pequeños
- permitir publicación compartible antes que features sociales avanzadas
- mantener la analítica ligada a `project_id`

## Documentación relacionada

- `docs/workflows/supabase_deployment_runbook.md`
- `agents/supabase_deployment_system_prompt.md`

## Siguiente iteración recomendada

1. conectar `apps/client_godot/` con `publish_project`
2. añadir ingestión de sesiones completas y cierre de sesión
3. ampliar `seed.sql` con catálogos o flags reales
4. documentar cualquier cambio contractual en `docs/architecture/`
