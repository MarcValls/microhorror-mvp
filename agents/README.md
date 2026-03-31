# Agents

Select the right agent prompt for the task you want to solve in this repository.

## Entry points

- `AGENTS.md` at the repository root — read by the GitHub Copilot Coding Agent and OpenAI Codex.
- `.github/copilot-instructions.md` — read by GitHub Copilot Chat in VS Code and the GitHub web editor.

Both files contain the same routing rules and project context.

## Available agents

- `agents/orchestrator_system_prompt.md`
  - Use for cross-functional planning, task decomposition, routing, and repo-wide decisions.

- `agents/product_scope_guardian_system_prompt.md`
  - Use for scope control, prioritization, acceptance criteria, roadmap alignment, and MVP decisions.

- `agents/godot_client_system_prompt.md`
  - Use for Godot 4.5 client work, scene architecture, scripts, runtime systems, and guided creation UI.

- `agents/supabase_backend_system_prompt.md`
  - Use for schema design, migrations, RLS, storage, functions, publication flow, and analytics.

- `agents/supabase_deployment_system_prompt.md`
  - Use for the exact rollout flow of migrations, seed data, secrets, edge function deployment, and post-deploy validation in Supabase.

- `agents/content_system_prompt.md`
  - Use for templates, threats, events, endings, presets, payload schemas, and content validation.

## Recommended default

If the task is unclear or touches several areas, start with `agents/orchestrator_system_prompt.md`.

If the backend schema already exists and the task is specifically about rollout, secrets, CLI steps, or remote validation, use `agents/supabase_deployment_system_prompt.md`.

## Repository structure cues

- Use `agents/supabase_deployment_system_prompt.md` when the main files are under `backend/supabase/scripts/`, `backend/supabase/.env.example`, `docs/workflows/supabase_deployment_runbook.md`, or `Makefile` deploy helpers.
- Use `agents/supabase_backend_system_prompt.md` when the main files are under `backend/supabase/migrations/`, `backend/supabase/functions/`, or `backend/supabase/seed/` and the task changes backend behavior or contracts.
- The current `backend/supabase/` tree contains legacy and consolidated SQL assets. The official rollout entrypoint is still `backend/supabase/scripts/deploy_remote.sh`, which currently applies `migrations/20260331_0001_init_schema.sql`, optionally applies `seed/seed.sql`, and deploys `publish_project` plus `ingest_analytics`.
- Additional assets such as `migrations/001_initial_schema.sql`, `migrations/002_generated_asset_unique.sql`, `seed/catalog.sql`, and `functions/generate_asset/` exist in the repo but are not automatically part of the current official staging rollout unless the task updates scripts and docs together.
- The former `functions/ingest_event/` implementation has been moved to `backend/supabase/legacy/functions/ingest_event/` as historical reference only.
