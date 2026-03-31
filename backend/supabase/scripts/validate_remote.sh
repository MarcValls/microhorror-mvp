#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPABASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${SUPABASE_DIR}/.env"
OFFICIAL_FUNCTIONS=(
  "publish_project"
  "ingest_analytics"
)

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

http_post_expect_200() {
  local name="$1"
  local url="$2"
  local bearer_token="$3"
  local payload="$4"
  local response_file
  local status_code

  response_file="$(mktemp)"
  status_code="$(curl -sS -o "${response_file}" -w "%{http_code}" -X POST "${url}" \
    -H "Authorization: Bearer ${bearer_token}" \
    -H "Content-Type: application/json" \
    -d "${payload}")"

  echo "==> ${name} response body"
  cat "${response_file}"
  echo

  if [[ "${status_code}" != "200" ]]; then
    echo "ERROR: ${name} returned HTTP ${status_code}" >&2
    rm -f "${response_file}"
    exit 1
  fi

  rm -f "${response_file}"
}

require_command "psql"
require_command "curl"

DEPLOY_ENVIRONMENT="${DEPLOY_ENVIRONMENT:-staging}"

if [[ "${DEPLOY_ENVIRONMENT}" != "staging" ]]; then
  echo "ERROR: this validation flow is hardened only for staging. Set DEPLOY_ENVIRONMENT='staging'." >&2
  exit 1
fi

require_env "SUPABASE_DB_URL"
require_env "SUPABASE_URL"
require_env "SUPABASE_ANON_KEY"

if command -v supabase >/dev/null 2>&1 && [[ -n "${SUPABASE_ACCESS_TOKEN:-}" ]] && [[ -n "${SUPABASE_PROJECT_REF:-}" ]]; then
  FUNCTIONS_LIST_OUTPUT="$(supabase functions list --project-ref "${SUPABASE_PROJECT_REF}")"
  echo "==> Validating deployed edge functions with Supabase CLI"
  echo "${FUNCTIONS_LIST_OUTPUT}"
  for function_name in "${OFFICIAL_FUNCTIONS[@]}"; do
    if ! printf '%s\n' "${FUNCTIONS_LIST_OUTPUT}" | grep -q "${function_name}"; then
      echo "ERROR: expected deployed function '${function_name}' was not found" >&2
      exit 1
    fi
  done
else
  echo "==> Skipping Supabase CLI function listing because supabase, SUPABASE_ACCESS_TOKEN, or SUPABASE_PROJECT_REF is missing"
fi

echo "==> Validating tables"
psql "${SUPABASE_DB_URL}" -c "select table_name from information_schema.tables where table_schema = 'public' and table_name in ('profiles', 'projects', 'play_sessions', 'generated_assets', 'analytics_events', 'feature_entitlements') order by table_name;"

echo "==> Validating SQL functions"
psql "${SUPABASE_DB_URL}" -c "select proname from pg_proc where proname in ('publish_project', 'generate_project_slug', 'log_analytics_event') order by proname;"

echo "==> Validating feature_entitlements seed"
psql "${SUPABASE_DB_URL}" -c "select plan_key, feature_key, is_enabled from public.feature_entitlements order by plan_key, feature_key;"

echo "==> Validating edge function ingest_analytics"
http_post_expect_200 \
  "ingest_analytics" \
  "${SUPABASE_URL}/functions/v1/ingest_analytics" \
  "${SUPABASE_ANON_KEY}" \
  '{"event_name":"project_link_opened","project_id":null,"session_id":null,"properties":{"source":"deployment_check","device_class":"manual"}}'

echo "==> Validating analytics_events aggregate view"
psql "${SUPABASE_DB_URL}" -c "select event_name, count(*) as total from public.analytics_events group by event_name order by event_name;"

if [[ -n "${SUPABASE_USER_ACCESS_TOKEN:-}" ]]; then
  echo "==> SUPABASE_USER_ACCESS_TOKEN detected, attempting functional publish_project validation"

  TEST_OWNER_ID="$(psql "${SUPABASE_DB_URL}" -t -A -c "select id from auth.users order by created_at asc limit 1;" | tr -d '[:space:]')"

  if [[ -z "${TEST_OWNER_ID}" ]]; then
    echo "==> Skipping publish_project validation because no auth.users rows were found"
    exit 0
  fi

  DEPLOY_TEST_PROJECT_ID="$(psql "${SUPABASE_DB_URL}" -t -A -c "insert into public.projects (owner_id, title, template_id, status, visibility) values ('${TEST_OWNER_ID}', 'Deployment Check Project', 'abandoned_house', 'draft', 'private') returning id;" | tr -d '[:space:]')"

  if [[ -z "${DEPLOY_TEST_PROJECT_ID}" ]]; then
    echo "ERROR: failed to create deployment test project" >&2
    exit 1
  fi

  export DEPLOY_TEST_PROJECT_ID

  echo "==> Invoking publish_project for project ${DEPLOY_TEST_PROJECT_ID}"
  http_post_expect_200 \
    "publish_project" \
    "${SUPABASE_URL}/functions/v1/publish_project" \
    "${SUPABASE_USER_ACCESS_TOKEN}" \
    "{\"project_id\":\"${DEPLOY_TEST_PROJECT_ID}\"}"

  echo "==> Validating published project state"
  psql "${SUPABASE_DB_URL}" -c "select id, title, status, visibility, publish_slug, published_at from public.projects where id = '${DEPLOY_TEST_PROJECT_ID}';"
else
  echo "==> Skipping functional publish_project validation because SUPABASE_USER_ACCESS_TOKEN is not set"
fi

echo "==> Validation finished"
