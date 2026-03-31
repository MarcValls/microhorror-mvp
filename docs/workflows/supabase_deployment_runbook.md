# Supabase deployment runbook

## Objetivo

Desplegar la base actual de `backend/supabase/` sobre un proyecto remoto de Supabase con un flujo repetible y verificable.

Este runbook cubre:

- migración inicial `20260331_0001_init_schema.sql`
- seed mínimo `seed.sql`
- edge functions `publish_project` e `ingest_analytics`
- variables y secretos requeridos
- scripts automatizados para despliegue y validación
- validaciones posteriores al despliegue

## Archivos usados en el despliegue

- `/backend/supabase/.env.example`
- `/backend/supabase/migrations/20260331_0001_init_schema.sql`
- `/backend/supabase/seed/seed.sql`
- `/backend/supabase/functions/publish_project/index.ts`
- `/backend/supabase/functions/ingest_analytics/index.ts`
- `/backend/supabase/functions/_shared/cors.ts`
- `/backend/supabase/functions/import_map.json`
- `/backend/supabase/scripts/deploy_remote.sh`
- `/backend/supabase/scripts/validate_remote.sh`

## Flujo recomendado

El flujo recomendado ya no es ejecutar el runbook paso por paso a mano.

El flujo recomendado es:

1. copiar `backend/supabase/.env.example` a `backend/supabase/.env`
2. rellenar variables reales
3. ejecutar `backend/supabase/scripts/deploy_remote.sh`
4. dejar que el propio script dispare validación si `DEPLOY_RUN_VALIDATION="1"`

## Requisitos previos

Antes de empezar necesitas:

- un proyecto remoto de Supabase ya creado
- `project ref` del proyecto remoto
- Supabase CLI instalada
- `psql` instalado para aplicar SQL directo
- `curl` instalado para validar edge functions
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- un token de usuario válido para probar `publish_project` si quieres validación funcional completa

## Paso 1 — Preparar variables

### 1.1 Copiar archivo de entorno

```bash
cp "backend/supabase/.env.example" "backend/supabase/.env"
```

### 1.2 Editar `backend/supabase/.env`

Valores mínimos obligatorios:

- `SUPABASE_PROJECT_REF`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_DB_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Valores opcionales pero recomendados:

- `SUPABASE_USER_ACCESS_TOKEN`
- `DEPLOY_RUN_SEED`
- `DEPLOY_RUN_VALIDATION`

Configuración recomendada para la primera ejecución:

```bash
DEPLOY_RUN_SEED="1"
DEPLOY_RUN_VALIDATION="1"
```

## Paso 2 — Lanzar despliegue automático

Desde la raíz del repositorio:

```bash
bash "backend/supabase/scripts/deploy_remote.sh"
```

## Qué hace `deploy_remote.sh`

El script ejecuta automáticamente:

1. comprobación de `supabase` y `psql`
2. carga de `backend/supabase/.env` si existe
3. validación de variables obligatorias
4. `supabase login --token`
5. `supabase link --project-ref`
6. aplicación de `20260331_0001_init_schema.sql`
7. carga de `seed.sql` si `DEPLOY_RUN_SEED="1"`
8. publicación de secretos `SUPABASE_URL` y `SUPABASE_ANON_KEY`
9. despliegue de `publish_project`
10. despliegue de `ingest_analytics`
11. validación automática si `DEPLOY_RUN_VALIDATION="1"`

## Qué hace `validate_remote.sh`

El script ejecuta automáticamente:

1. validación de tablas principales
2. validación de funciones SQL
3. validación del seed de `feature_entitlements`
4. prueba HTTP de `ingest_analytics`
5. validación funcional de `publish_project` si existe `SUPABASE_USER_ACCESS_TOKEN`
6. comprobación final de analítica agregada

## Comandos manuales equivalentes

Usa esta sección solo si necesitas aislar fallos o ejecutar pasos sueltos.

### Variables de shell equivalentes

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

### Login y link

```bash
supabase login --token "${SUPABASE_ACCESS_TOKEN}"
cd "${REPO_ROOT}"
supabase link --project-ref "${SUPABASE_PROJECT_REF}"
```

### Aplicar migración y seed

```bash
psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${SUPABASE_DIR}/migrations/20260331_0001_init_schema.sql"
psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${SUPABASE_DIR}/seed/seed.sql"
```

### Publicar secretos

```bash
supabase secrets set SUPABASE_URL="${SUPABASE_URL}" SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" --project-ref "${SUPABASE_PROJECT_REF}"
```

### Desplegar edge functions

```bash
supabase functions deploy publish_project --project-ref "${SUPABASE_PROJECT_REF}" --import-map "${SUPABASE_DIR}/functions/import_map.json"
supabase functions deploy ingest_analytics --project-ref "${SUPABASE_PROJECT_REF}" --import-map "${SUPABASE_DIR}/functions/import_map.json"
```

## Validaciones esperadas

### Validación de tablas

```bash
psql "${SUPABASE_DB_URL}" -c "select table_name from information_schema.tables where table_schema = 'public' and table_name in ('profiles', 'projects', 'play_sessions', 'generated_assets', 'analytics_events', 'feature_entitlements') order by table_name;"
```

### Validación de funciones SQL

```bash
psql "${SUPABASE_DB_URL}" -c "select proname from pg_proc where proname in ('publish_project', 'generate_project_slug', 'log_analytics_event') order by proname;"
```

### Validación de `ingest_analytics`

```bash
curl -i -X POST "${SUPABASE_URL}/functions/v1/ingest_analytics" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"event_name":"project_link_opened","project_id":null,"session_id":null,"properties":{"source":"deployment_check","device_class":"manual"}}'
```

Resultado esperado:

- estado HTTP `200`
- cuerpo JSON con `analytics_event_id`

## Qué hacer si falla un paso

### Si falla `deploy_remote.sh`

- revisar la primera línea que empiece por `ERROR:`
- corregir variable, herramienta o credencial indicada
- volver a ejecutar el mismo script completo

### Si falla la migración

- revisar conectividad de `SUPABASE_DB_URL`
- revisar permisos del usuario de base de datos
- reintentar con el comando SQL manual equivalente

### Si falla el seed

- confirmar que la migración se aplicó antes
- volver a ejecutar con `DEPLOY_RUN_SEED="1"`

### Si falla el despliegue de functions

- revisar autenticación CLI
- revisar `SUPABASE_PROJECT_REF`
- revisar sintaxis TypeScript en las functions
- reintentar `bash "backend/supabase/scripts/deploy_remote.sh"`

### Si falla `publish_project`

- revisar que `SUPABASE_USER_ACCESS_TOKEN` pertenezca al dueño del proyecto de prueba
- revisar que exista al menos un usuario en `auth.users`
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
