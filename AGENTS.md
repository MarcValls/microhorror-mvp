# Agent Routing

Create or modify this repository while protecting MVP scope, preserving a data-driven architecture, and prioritizing the loop crear -> publicar -> jugar -> compartir.

This repository is for the MVP of a mobile first-person micro-horror platform. The current technical direction is Godot 4.5 for the client, Supabase for the backend, and a data-driven content layer. The MVP must validate whether a creator can build a short experience from a closed template, publish it through a shareable link, and generate real measurable play sessions.

## Repository Constants

- Client stack: Godot 4.5
- Backend stack: Supabase
- Content model: data-driven templates, threats, events, endings, and presets
- Distribution model: mobile app with shareable link publication
- Target loop: crear -> publicar -> jugar -> compartir
- MVP constraints:
  - no general-purpose game engine inside the product
  - no free-form spatial editor
  - no full web gameplay in the MVP
  - no deep community features before validating the core loop

## Source of truth inside the repository

Read these files before proposing or implementing major changes:

- `README.md`
- `docs/product/scope_mvp.md`
- `docs/product/user_flows.md`
- `docs/mvp/roadmap_mvp.md`
- `docs/mvp/backlog_p0.md`
- `docs/mvp/backlog_p1.md`
- `docs/mvp/acceptance_criteria.md`
- `docs/architecture/system_overview.md`
- `docs/architecture/data_model.md`
- `docs/architecture/analytics_events.md`
- `planning/sprint_01.md`
- `agents/README.md`
- `backend/supabase/README.md`
- `backend/supabase/.env.example`
- `docs/workflows/supabase_deployment_runbook.md`

## Agent routing

Use the agent that best matches the task:

- `agents/orchestrator_system_prompt.md` for cross-cutting planning, repo-wide decisions, and task routing
- `agents/product_scope_guardian_system_prompt.md` for scope control, prioritization, roadmap, acceptance criteria, and PMF-oriented decisions
- `agents/godot_client_system_prompt.md` for Godot client architecture, scenes, scripts, runtime systems, and editor UX inside the app
- `agents/supabase_backend_system_prompt.md` for schema design, SQL migrations, RLS, storage, functions, publication, analytics, and backend contracts
- `agents/supabase_deployment_system_prompt.md` for the exact rollout flow of migrations, seed, secrets, edge functions, and post-deploy validation in Supabase
- `agents/content_system_prompt.md` for content definitions, template catalogs, payload schemas, validation rules, and scalable data-driven authoring

## Required routing discipline

- Start with `agents/orchestrator_system_prompt.md` when the task is ambiguous, cross-functional, or changes more than one area.
- Route deployment work to `agents/supabase_deployment_system_prompt.md` when the dominant paths are `backend/supabase/scripts/`, `backend/supabase/.env.example`, `docs/workflows/supabase_deployment_runbook.md`, or the task is about rollout, secrets, remote apply, or post-deploy validation.
- Route backend implementation work to `agents/supabase_backend_system_prompt.md` when the dominant paths are `backend/supabase/migrations/`, `backend/supabase/functions/`, `backend/supabase/seed/`, or the task changes schema, RLS, SQL functions, or backend contracts.
- Return to the orchestrator when a specialist change also modifies architecture docs, shared contracts, or routing rules.

## Collaboration rules

- Reason before conclusions. Present analysis, tradeoffs, and validation checks before the final recommendation, plan, patch, or implementation summary.
- Keep conclusions last.
- Prefer the smallest change that moves the MVP forward.
- Reject or defer work that expands beyond current MVP constraints unless the task explicitly asks for post-MVP exploration.
- When code or file edits are proposed, reference exact repository paths.
- Keep new files and text UTF-8 encoded.
- Preserve consistency across `docs/`, `backend/`, `content/`, and `apps/client_godot/`.
- If architecture and implementation drift, align implementation to the documented MVP unless there is a strong reason to update the docs too.

## Default working style

1. Read the relevant repository documents.
2. Identify the goal, affected paths, and MVP impact.
3. Explain assumptions, dependencies, and tradeoffs.
4. Produce the concrete output requested.
5. End with the final recommendation, implementation summary, or next action.

## Output Format

Respond in markdown.

Use this structure unless the user explicitly requests another format:

1. `Contexto`
2. `Análisis`
3. `Cambios o propuesta`
4. `Riesgos o validaciones`
5. `Conclusión`

Keep `Conclusión` last.
