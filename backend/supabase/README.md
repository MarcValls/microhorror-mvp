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
│   ├── 001_initial_schema.sql
│   ├── 002_generated_asset_unique.sql
│   └── 20260331_0001_init_schema.sql
├── functions/
│   ├── _shared/
│   │   └── cors.ts
│   ├── generate_asset/
│   ├── import_map.json
│   ├── ingest_analytics/
│   │   └── index.ts
│   └── publish_project/
│       └── index.ts
├── legacy/
│   └── functions/
│       └── ingest_event/
│           └── index.ts
├── scripts/
│   ├── deploy_remote.sh
│   └── validate_remote.sh
└── seed/
    ├── catalog.sql
    └── seed.sql
```

## Estado operativo actual

El árbol versionado de `backend/supabase/` contiene más assets de backend que los que cubre hoy el rollout oficial de staging.

### Rollout oficial actual

El entrypoint operativo actual es `backend/supabase/scripts/deploy_remote.sh` y hoy hace exactamente esto:

- aplica `backend/supabase/migrations/20260331_0001_init_schema.sql`
- aplica `backend/supabase/seed/seed.sql` si `DEPLOY_RUN_SEED="1"`
- publica secretos para edge functions
- despliega `publish_project`
- despliega `ingest_analytics`
- ejecuta `backend/supabase/scripts/validate_remote.sh` si `DEPLOY_RUN_VALIDATION="1"`

### Assets presentes pero fuera del rollout oficial actual

Estos paths existen en el repo, pero no forman parte implícita del despliegue oficial actual salvo que una tarea actualice scripts y documentación a la vez:

- `backend/supabase/migrations/001_initial_schema.sql`
- `backend/supabase/migrations/002_generated_asset_unique.sql`
- `backend/supabase/seed/catalog.sql`
- `backend/supabase/functions/generate_asset/`

Asset histórico movido fuera del árbol activo:

- `backend/supabase/legacy/functions/ingest_event/`

En la práctica deben tratarse como assets legado o aún no integrados al baseline actual de staging. No deben entrar en el rollout oficial por defecto mientras no se alineen con el esquema y los secretos del flujo vigente.

## Qué crea esta base

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

- `DEPLOY_ENVIRONMENT="staging"`
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

- validación de entorno `staging`
- verificación de herramientas
- login de Supabase CLI
- link al proyecto remoto
- aplicación de migración
- carga de seed
- publicación de secretos
- despliegue de edge functions
- aviso de assets no incluidos en el rollout oficial
- validación opcional

### `backend/supabase/scripts/validate_remote.sh`

Automatiza:

- validación de entorno `staging`
- validación opcional de functions desplegadas si hay acceso CLI
- validación de tablas
- validación de funciones SQL
- validación de seed
- prueba de `ingest_analytics` con control explícito de HTTP `200`
- validación funcional de `publish_project` si existe `SUPABASE_USER_ACCESS_TOKEN`, también con control explícito de HTTP `200`

### `backend/supabase/functions/ingest_analytics/`

Contrato actual:

- acepta un evento individual o un batch de hasta 50 eventos
- aplica allow-list basada en `docs/architecture/analytics_events.md`
- conserva `analytics_event_id` como respuesta para el caso individual
- devuelve `ingested` y `analytics_event_ids` para batch

## Principios de implementación

- mantener distinción entre datos del creador, datos públicos publicados y sesiones anónimas
- usar SQL explícito y contratos pequeños
- permitir publicación compartible antes que features sociales avanzadas
- mantener la analítica ligada a `project_id`
- distinguir entre assets presentes en el árbol y assets incluidos en el rollout oficial

## Documentación relacionada

- `docs/workflows/supabase_deployment_runbook.md`
- `backend/supabase/asset_audit.md`
- `agents/supabase_deployment_system_prompt.md`

## Siguiente iteración recomendada

1. conectar `apps/client_godot/` con `publish_project`
2. añadir ingestión de sesiones completas y cierre de sesión
3. ampliar `seed.sql` con catálogos o flags reales
4. documentar cualquier cambio contractual en `docs/architecture/`
