# Supabase deployment runbook

## Objetivo

Desplegar la base actual de `backend/supabase/` sobre un proyecto remoto de Supabase con un flujo repetible y verificable.

Este runbook cubre:

- migración inicial `20260331_0001_init_schema.sql`
- seed mínimo `seed.sql`
- edge functions `publish_project` e `ingest_analytics`
- variables y secretos requeridos
- validaciones posteriores al despliegue

## Archivos usados en el despliegue

- `/backend/supabase/migrations/20260331_0001_init_schema.sql`
- `/backend/supabase/seed/seed.sql`
- `/backend/supabase/functions/publish_project/index.ts`
- `/backend/supabase/functions/ingest_analytics/index.ts`
- `/backend/supabase/functions/_shared/cors.ts`
- `/backend/supabase/.env.example`

## Requisitos previos

Antes de empezar necesitas:

- un proyecto remoto de Supabase ya creado
- `project ref` del proyecto remoto
- Supabase CLI instalada
- `psql` instalado para aplicar seed con URL directa
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- un token de usuario válido para probar `publish_project` si quieres validación funcional completa

## Variables exactas

Ejecuta estos comandos desde la raíz local del repositorio:

```bash
export REPO_ROOT="$(pwd)"
export SUPABASE_DIR="${REPO_ROOT}/backend/supabase"
export SUPABASE_PROJECT_REF="TU_PROJECT_REF"
export SUPABASE_ACCESS_TOKEN="TU_SUPABASE_ACCESS_TOKEN"
export SUPABASE_DB_URL="TU_SUPABASE_DB_URL"
export SUPABASE_URL="https://${SUPABASE_PROJECT_REF}.supabase.co"
export SUPABASE_ANON_KEY="TU_SUPABASE_ANON_KEY"
export SUPABASE_USER_ACCESS_TOKEN="TU_USER_ACCESS_TOKEN_PARA_PRUEBAS_FUNCIONALES"
```

## Paso 1 — Verificar herramientas

```bash
supabase --version
psql --version
```

## Paso 2 — Autenticación de Supabase CLI

```bash
supabase login --token "${SUPABASE_ACCESS_TOKEN}"
```

## Paso 3 — Enlazar el proyecto remoto

Este comando debe ejecutarse desde la raíz del repositorio:

```bash
cd "${REPO_ROOT}"
supabase link --project-ref "${SUPABASE_PROJECT_REF}"
```

## Paso 4 — Aplicar la migración inicial

La migración actual está en una ruta personalizada del repo, así que se aplica directamente con `psql`:

```bash
psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${SUPABASE_DIR}/migrations/20260331_0001_init_schema.sql"
```

## Paso 5 — Cargar seed mínimo

```bash
psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${SUPABASE_DIR}/seed/seed.sql"
```

## Paso 6 — Publicar secretos requeridos para edge functions

```bash
supabase secrets set SUPABASE_URL="${SUPABASE_URL}" SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" --project-ref "${SUPABASE_PROJECT_REF}"
```

## Paso 7 — Desplegar edge functions

Ejecuta estos comandos desde la raíz del repositorio:

```bash
cd "${REPO_ROOT}"
supabase functions deploy publish_project --project-ref "${SUPABASE_PROJECT_REF}" --import-map "${SUPABASE_DIR}/functions/import_map.json"
supabase functions deploy ingest_analytics --project-ref "${SUPABASE_PROJECT_REF}" --import-map "${SUPABASE_DIR}/functions/import_map.json"
```

## Paso 8 — Validar tablas y funciones SQL

### 8.1 Validar tablas principales

```bash
psql "${SUPABASE_DB_URL}" -c "select table_name from information_schema.tables where table_schema = 'public' and table_name in ('profiles', 'projects', 'play_sessions', 'generated_assets', 'analytics_events', 'feature_entitlements') order by table_name;"
```

### 8.2 Validar que existe la función SQL de publicación

```bash
psql "${SUPABASE_DB_URL}" -c "select proname from pg_proc where proname in ('publish_project', 'generate_project_slug', 'log_analytics_event') order by proname;"
```

### 8.3 Validar seed de planes

```bash
psql "${SUPABASE_DB_URL}" -c "select plan_key, feature_key, is_enabled from public.feature_entitlements order by plan_key, feature_key;"
```

## Paso 9 — Validar edge function `ingest_analytics`

Esta validación no requiere un token de usuario real, basta con el anon key.

```bash
curl -i -X POST "${SUPABASE_URL}/functions/v1/ingest_analytics" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"event_name":"project_link_opened","project_id":null,"session_id":null,"properties":{"source":"deployment_check","device_class":"manual"}}'
```

### Resultado esperado

- estado HTTP `200`
- cuerpo JSON con `analytics_event_id`

## Paso 10 — Validar edge function `publish_project`

Para esta prueba hace falta un `project_id` existente y un token de usuario propietario del proyecto.

### 10.1 Crear un proyecto de prueba directamente en SQL

```bash
psql "${SUPABASE_DB_URL}" -t -A -c "insert into public.projects (owner_id, title, template_id, status, visibility) values ((select id from auth.users order by created_at asc limit 1), 'Deployment Check Project', 'car_template', 'draft', 'private') returning id;"
```

Guarda el valor devuelto en una variable:

```bash
export DEPLOY_TEST_PROJECT_ID="PEGA_AQUI_EL_PROJECT_ID_DEVUELTO"
```

### 10.2 Invocar `publish_project`

```bash
curl -i -X POST "${SUPABASE_URL}/functions/v1/publish_project" \
  -H "Authorization: Bearer ${SUPABASE_USER_ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"project_id\":\"${DEPLOY_TEST_PROJECT_ID}\"}"
```

### Resultado esperado

- estado HTTP `200`
- cuerpo JSON con `project.publish_slug`
- `status` igual a `published`

## Paso 11 — Validar el cambio de estado del proyecto

```bash
psql "${SUPABASE_DB_URL}" -c "select id, title, status, visibility, publish_slug, published_at from public.projects where id = '${DEPLOY_TEST_PROJECT_ID}';"
```

## Paso 12 — Comprobación final de analítica

```bash
psql "${SUPABASE_DB_URL}" -c "select event_name, count(*) as total from public.analytics_events group by event_name order by event_name;"
```

## Qué hacer si falla un paso

### Si falla la migración

- revisar conectividad de `SUPABASE_DB_URL`
- revisar permisos del usuario de base de datos
- volver a ejecutar solo el paso 4 tras corregir el error

### Si falla el seed

- revisar que la migración se haya aplicado antes
- volver a ejecutar solo el paso 5

### Si falla el despliegue de functions

- revisar autenticación CLI
- revisar `SUPABASE_PROJECT_REF`
- revisar sintaxis TypeScript en cada function
- volver a ejecutar solo el paso 7

### Si falla `publish_project`

- revisar que `SUPABASE_USER_ACCESS_TOKEN` pertenezca al dueño del proyecto
- revisar que el proyecto exista y tenga `title` y `template_id`
- revisar respuesta JSON devuelta por la function

## Resultado de un despliegue correcto

Un despliegue correcto deja el proyecto con:

- tablas principales creadas
- RLS activada
- `feature_entitlements` con seed mínimo
- `publish_project` desplegada
- `ingest_analytics` desplegada
- capacidad de registrar eventos
- capacidad de publicar un proyecto con slug
