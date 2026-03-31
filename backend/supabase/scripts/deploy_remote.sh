#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPABASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SUPABASE_DIR}/../.." && pwd)"
ENV_FILE="${SUPABASE_DIR}/.env"
VALIDATE_SCRIPT="${SUPABASE_DIR}/scripts/validate_remote.sh"
IMPORT_MAP_FILE="${SUPABASE_DIR}/functions/import_map.json"
MIGRATION_FILE="${SUPABASE_DIR}/migrations/20260331_0001_init_schema.sql"
SEED_FILE="${SUPABASE_DIR}/seed/seed.sql"

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

require_command "supabase"
require_command "psql"

require_env "SUPABASE_PROJECT_REF"
require_env "SUPABASE_ACCESS_TOKEN"
require_env "SUPABASE_DB_URL"
require_env "SUPABASE_URL"
require_env "SUPABASE_ANON_KEY"

DEPLOY_RUN_SEED="${DEPLOY_RUN_SEED:-1}"
DEPLOY_RUN_VALIDATION="${DEPLOY_RUN_VALIDATION:-0}"

echo "==> Repository root: ${REPO_ROOT}"
echo "==> Supabase directory: ${SUPABASE_DIR}"
echo "==> Target project ref: ${SUPABASE_PROJECT_REF}"

echo "==> Checking tool versions"
supabase --version
psql --version

echo "==> Logging in to Supabase CLI"
supabase login --token "${SUPABASE_ACCESS_TOKEN}"

echo "==> Linking local repository to remote Supabase project"
cd "${REPO_ROOT}"
supabase link --project-ref "${SUPABASE_PROJECT_REF}"

echo "==> Applying migration file ${MIGRATION_FILE}"
psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${MIGRATION_FILE}"

if [[ "${DEPLOY_RUN_SEED}" == "1" ]]; then
  echo "==> Applying seed file ${SEED_FILE}"
  psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${SEED_FILE}"
else
  echo "==> Skipping seed because DEPLOY_RUN_SEED=${DEPLOY_RUN_SEED}"
fi

echo "==> Publishing Supabase secrets required by edge functions"
supabase secrets set SUPABASE_URL="${SUPABASE_URL}" SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" --project-ref "${SUPABASE_PROJECT_REF}"

echo "==> Deploying edge function publish_project"
supabase functions deploy publish_project --project-ref "${SUPABASE_PROJECT_REF}" --import-map "${IMPORT_MAP_FILE}"

echo "==> Deploying edge function ingest_analytics"
supabase functions deploy ingest_analytics --project-ref "${SUPABASE_PROJECT_REF}" --import-map "${IMPORT_MAP_FILE}"

if [[ "${DEPLOY_RUN_VALIDATION}" == "1" ]]; then
  echo "==> Running post-deploy validation"
  bash "${VALIDATE_SCRIPT}"
else
  echo "==> Deployment finished. Validation not executed because DEPLOY_RUN_VALIDATION=${DEPLOY_RUN_VALIDATION}"
  echo "==> To validate now, run: bash ${VALIDATE_SCRIPT}"
fi
