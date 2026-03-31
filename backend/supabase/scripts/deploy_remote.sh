#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPABASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SUPABASE_DIR}/../.." && pwd)"
ENV_FILE="${SUPABASE_DIR}/.env"
VALIDATE_SCRIPT="${SUPABASE_DIR}/scripts/validate_remote.sh"
IMPORT_MAP_FILE="${SUPABASE_DIR}/functions/import_map.json"
OFFICIAL_MIGRATION_FILES=(
  "${SUPABASE_DIR}/migrations/20260331_0001_init_schema.sql"
)
OFFICIAL_SEED_FILES=(
  "${SUPABASE_DIR}/seed/seed.sql"
)
OFFICIAL_FUNCTIONS=(
  "publish_project"
  "ingest_analytics"
)
NON_ROLLOUT_ASSETS=(
  "${SUPABASE_DIR}/migrations/001_initial_schema.sql"
  "${SUPABASE_DIR}/migrations/002_generated_asset_unique.sql"
  "${SUPABASE_DIR}/seed/catalog.sql"
  "${SUPABASE_DIR}/functions/generate_asset"
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

require_file() {
  local file_path="$1"
  if [[ ! -e "${file_path}" ]]; then
    echo "ERROR: required path not found '${file_path}'" >&2
    exit 1
  fi
}

print_non_rollout_assets() {
  local asset_path
  local found_any="0"

  for asset_path in "${NON_ROLLOUT_ASSETS[@]}"; do
    if [[ -e "${asset_path}" ]]; then
      if [[ "${found_any}" == "0" ]]; then
        echo "==> Note: the repository contains additional Supabase assets outside the official staging rollout:"
        found_any="1"
      fi
      echo "    - ${asset_path}"
    fi
  done

  if [[ "${found_any}" == "1" ]]; then
    echo "==> These assets are intentionally excluded from the current staging deploy entrypoint."
  fi
}

require_command "supabase"
require_command "psql"

DEPLOY_ENVIRONMENT="${DEPLOY_ENVIRONMENT:-staging}"
DEPLOY_RUN_SEED="${DEPLOY_RUN_SEED:-1}"
DEPLOY_RUN_VALIDATION="${DEPLOY_RUN_VALIDATION:-0}"

require_env "SUPABASE_PROJECT_REF"
require_env "SUPABASE_ACCESS_TOKEN"
require_env "SUPABASE_DB_URL"
if [[ "${DEPLOY_ENVIRONMENT}" != "staging" ]]; then
  echo "ERROR: this deploy flow is hardened only for staging. Set DEPLOY_ENVIRONMENT='staging'." >&2
  exit 1
fi

if [[ "${DEPLOY_RUN_VALIDATION}" == "1" ]]; then
  require_command "curl"
fi
require_env "SUPABASE_URL"
require_env "SUPABASE_ANON_KEY"

require_file "${IMPORT_MAP_FILE}"
require_file "${VALIDATE_SCRIPT}"

for migration_file in "${OFFICIAL_MIGRATION_FILES[@]}"; do
  require_file "${migration_file}"
done

for seed_file in "${OFFICIAL_SEED_FILES[@]}"; do
  require_file "${seed_file}"
done

for function_name in "${OFFICIAL_FUNCTIONS[@]}"; do
  require_file "${SUPABASE_DIR}/functions/${function_name}"
done

echo "==> Repository root: ${REPO_ROOT}"
echo "==> Supabase directory: ${SUPABASE_DIR}"
echo "==> Target project ref: ${SUPABASE_PROJECT_REF}"
echo "==> Checking tool versions"
supabase --version
echo "==> Target environment: ${DEPLOY_ENVIRONMENT}"
psql --version

if [[ -f "${ENV_FILE}" ]]; then
  echo "==> Using local operator environment file ${ENV_FILE}"
else
  echo "==> No local ${ENV_FILE} found. Falling back to exported environment variables."
fi

print_non_rollout_assets

echo "==> Logging in to Supabase CLI"
supabase login --token "${SUPABASE_ACCESS_TOKEN}"

echo "==> Linking local repository to remote Supabase project"
cd "${REPO_ROOT}"
supabase link --project-ref "${SUPABASE_PROJECT_REF}"

for migration_file in "${OFFICIAL_MIGRATION_FILES[@]}"; do
  echo "==> Applying migration file ${migration_file}"
  psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${migration_file}"
done

if [[ "${DEPLOY_RUN_SEED}" == "1" ]]; then
  for seed_file in "${OFFICIAL_SEED_FILES[@]}"; do
    echo "==> Applying seed file ${seed_file}"
    psql "${SUPABASE_DB_URL}" -v ON_ERROR_STOP=1 -f "${seed_file}"
  done
else
  echo "==> Skipping seed because DEPLOY_RUN_SEED=${DEPLOY_RUN_SEED}"
fi

echo "==> Publishing Supabase secrets required by edge functions"
supabase secrets set SUPABASE_URL="${SUPABASE_URL}" SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" --project-ref "${SUPABASE_PROJECT_REF}"

for function_name in "${OFFICIAL_FUNCTIONS[@]}"; do
  echo "==> Deploying edge function ${function_name}"
  supabase functions deploy "${function_name}" --project-ref "${SUPABASE_PROJECT_REF}" --import-map "${IMPORT_MAP_FILE}"
done

if [[ "${DEPLOY_RUN_VALIDATION}" == "1" ]]; then
  echo "==> Running post-deploy validation"
  bash "${VALIDATE_SCRIPT}"
else
  echo "==> Deployment finished. Validation not executed because DEPLOY_RUN_VALIDATION=${DEPLOY_RUN_VALIDATION}"
  echo "==> To validate now, run: bash ${VALIDATE_SCRIPT}"
fi
