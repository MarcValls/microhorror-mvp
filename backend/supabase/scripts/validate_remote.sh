#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPABASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${SUPABASE_DIR}/.env"

if [[ -f "${ENV_FILE}" ]]; then
  set -a
  source "${ENV_FILE}"
  set +a
fi

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "ERROR: missing required command '${command_name}'" >&2
    exit 1
  fi
}

require_env() {
  local variable_name="$1"
  if [[ -z "${!variable_name:-}" ]]; then
    echo "ERROR: missing required environment variable '${variable_name}'" >&2
    exit 1
  fi
}

require_command "psql"
require_command "curl"

require_env "SUPABASE_DB_URL"
require_env "SUPABASE_URL"
require_env "SUPABASE_ANON_KEY"

echo "==> Validating tables"
psql "${SUPABASE_DB_URL}" -c "select table_name from information_schema.tables where table_schema = 'public' and table_name in ('profiles', 'projects', 'play_sessions', 'generated_assets', 'analytics_events', 'feature_entitlements') order by table_name;"

echo "==> Validating SQL functions"
psql "${SUPABASE_DB_URL}" -c "select proname from pg_proc where proname in ('publish_project', 'generate_project_slug', 'log_analytics_event') order by proname;"

echo "==> Validating feature_entitlements seed"
psql "${SUPABASE_DB_URL}" -c "select plan_key, feature_key, is_enabled from public.feature_entitlements order by plan_key, feature_key;"

echo "==> Validating edge function ingest_analytics"
curl -i -X POST "${SUPABASE_URL}/functions/v1/ingest_analytics" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"event_name":"project_link_opened","project_id":null,"session_id":null,"properties":{"source":"deployment_check","device_class":"manual"}}'

echo "==> Validating analytics_events aggregate view"
psql "${SUPABASE_DB_URL}" -c "select event_name, count(*) as total from public.analytics_events group by event_name order by event_name;"

if [[ -n "${SUPABASE_USER_ACCESS_TOKEN:-}" ]]; then
  echo "==> SUPABASE_USER_ACCESS_TOKEN detected, attempting functional publish_project validation"

  TEST_OWNER_ID="$(psql "${SUPABASE_DB_URL}" -t -A -c "select id from auth.users order by created_at asc limit 1;" | tr -d '[:space:]')"

  if [[ -z "${TEST_OWNER_ID}" ]]; then
    echo "==> Skipping publish_project validation because no auth.users rows were found"
    exit 0
  fi

  DEPLOY_TEST_PROJECT_ID="$(psql "${SUPABASE_DB_URL}" -t -A -c "insert into public.projects (owner_id, title, template_id, status, visibility) values ('${TEST_OWNER_ID}', 'Deployment Check Project', 'car_template', 'draft', 'private') returning id;" | tr -d '[:space:]')"

  if [[ -z "${DEPLOY_TEST_PROJECT_ID}" ]]; then
    echo "ERROR: failed to create deployment test project" >&2
    exit 1
  fi

  export DEPLOY_TEST_PROJECT_ID

  echo "==> Invoking publish_project for project ${DEPLOY_TEST_PROJECT_ID}"
  curl -i -X POST "${SUPABASE_URL}/functions/v1/publish_project" \
    -H "Authorization: Bearer ${SUPABASE_USER_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"project_id\":\"${DEPLOY_TEST_PROJECT_ID}\"}"

  echo "==> Validating published project state"
  psql "${SUPABASE_DB_URL}" -c "select id, title, status, visibility, publish_slug, published_at from public.projects where id = '${DEPLOY_TEST_PROJECT_ID}';"
else
  echo "==> Skipping functional publish_project validation because SUPABASE_USER_ACCESS_TOKEN is not set"
fi

echo "==> Validation finished"
