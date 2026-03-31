Create or modify this repository while protecting MVP scope, preserving a data-driven architecture, and prioritizing the loop crear -> publicar -> jugar -> compartir.

This repository is for the MVP of a mobile first-person micro-horror platform. The current technical direction is Godot 4.5 for the client, Supabase for the backend, and a data-driven content layer. The MVP must validate whether a creator can build a short experience from a closed template, publish it through a shareable link, and generate real measurable play sessions.

## Repository Constants

- Client stack: Godot 4.5
- Backend stack: Supabase
- Content model: data-driven templates, threats, events, endings, presets, and constrained payloads
- Distribution model: mobile app with shareable link publication
- Target loop: crear -> publicar -> jugar -> compartir
- MVP constraints:
  - no general-purpose game engine inside the product
  - no free-form spatial editor
  - no arbitrary scripting in creator content
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
- `AGENTS.md`
- `agents/README.md`
- `docs/workflows/task_brief_template.md`
- `docs/workflows/handoff_template.md`
- `docs/workflows/supabase_deployment_runbook.md`
- `backend/supabase/README.md`
- `backend/supabase/.env.example`
- `.github/ISSUE_TEMPLATE/nueva_tarea.md`
- `.github/pull_request_template.md`

## Agent routing

Use the agent that best matches the task:

- `agents/orchestrator_system_prompt.md`
  - Use for cross-cutting planning, repo-wide decisions, task routing, and consistency checks across domains.
- `agents/product_scope_guardian_system_prompt.md`
  - Use for scope control, prioritization, acceptance criteria, roadmap alignment, and PMF-oriented product decisions.
- `agents/godot_client_system_prompt.md`
  - Use for Godot client architecture, scenes, scripts, runtime systems, playtest flow, and guided creation UX inside the app.
- `agents/supabase_backend_system_prompt.md`
  - Use for schema design, migrations, RLS, storage, functions, publication, analytics, and backend contracts.
- `agents/supabase_deployment_system_prompt.md`
  - Use for the exact rollout flow of migrations, seed data, secrets, edge function deployment, and post-deploy validation in Supabase.
- `agents/content_system_prompt.md`
  - Use for template catalogs, threats, events, endings, payload schemas, validation rules, and scalable data-driven authoring.

## Required routing discipline

- Start with the orchestrator when the task is ambiguous, cross-functional, or affects more than one area.
- Route to exactly one specialist when a task has a clear dominant domain.
- Use the Supabase deployment agent when the schema already exists and the task is about rollout, secrets, remote apply, edge function deployment, or post-deploy verification.
- Treat `backend/supabase/scripts/`, `backend/supabase/.env.example`, `docs/workflows/supabase_deployment_runbook.md`, and deploy helpers in `Makefile` as deployment-domain entry points.
- Treat `backend/supabase/migrations/`, `backend/supabase/functions/`, and `backend/supabase/seed/` as backend-domain entry points unless the task is only about rollout mechanics.
- Return to the orchestrator when a specialist change affects architecture, documentation, contracts, or another domain.
- Do not let product decisions be made by the Godot or Supabase agents unless the task explicitly asks for implementation tradeoffs.
- Do not let backend or client agents expand scope beyond documented MVP constraints.

## Collaboration rules

- Reason before conclusions. Present analysis, tradeoffs, validation checks, and assumptions before the final recommendation, plan, patch, or implementation summary.
- Keep conclusions last.
- Prefer the smallest change that moves the MVP forward.
- Reject, defer, or reframe work that expands beyond current MVP constraints unless the task explicitly asks for post-MVP exploration.
- When code or file edits are proposed, reference exact repository paths.
- Keep new files and text UTF-8 encoded.
- Preserve consistency across `docs/`, `backend/`, `content/`, and `apps/client_godot/`.
- If architecture and implementation drift, align implementation to the documented MVP unless there is a strong reason to update the docs too.
- If a change introduces or modifies a contract between domains, update the relevant documentation in the same task.

## When documentation must be updated

Update documentation when any of these are true:

- a data model field, state machine, identifier, or payload schema changes
- an analytics event name, required property, or meaning changes
- a publication flow, onboarding flow, or playtest flow changes
- a new folder, subsystem, or architectural convention is introduced
- an MVP acceptance criterion, scope boundary, or backlog classification changes
- a deployment flow, secret requirement, function rollout step, or validation procedure changes

Likely documentation targets:

- `docs/architecture/data_model.md`
- `docs/architecture/analytics_events.md`
- `docs/architecture/system_overview.md`
- `docs/product/scope_mvp.md`
- `docs/product/user_flows.md`
- `docs/mvp/backlog_p0.md`
- `docs/mvp/backlog_p1.md`
- `docs/mvp/acceptance_criteria.md`
- `planning/sprint_01.md`
- `docs/workflows/supabase_deployment_runbook.md`
- `backend/supabase/README.md`

## Domain-specific expectations

### Product and scope

- classify requests as P0 now, P1 after core validation, post-MVP exploration, or reject for current scope
- prioritize creation, playtest, publication, link opening, game session completion, and result sharing
- reframe oversized ideas into MVP-safe slices when possible

### Godot client

- keep the client data-driven and mobile-first
- prefer reusable scenes, resources, and scripts over template-specific hardcoded logic
- do not turn guided creation into a free-form editor
- include analytics hooks for creation, playtest, publication entry, and session completion when relevant

### Supabase backend

- model creator-owned data, public published data, and anonymous session data explicitly
- keep SQL, migrations, RLS, and function contracts small and clear
- make publication and slug semantics explicit
- keep analytics linked to `project_id` and event names documented in the repo

### Supabase deployment

- define variables once and reuse exact paths afterward
- separate one-time setup from repeatable rollout steps
- prefer exact commands over vague descriptions
- validate tables, SQL functions, edge functions, and analytics after deployment
- call out secrets and tokens explicitly

### Content system

- keep templates, threats, events, endings, and presets declarative and versionable
- use stable identifiers and constrained payloads
- avoid arbitrary logic embedded in content definitions
- favor a small number of strong content variations over a large weak catalog

## Workflow templates to use

When appropriate, structure work using repository templates:

- use `.github/ISSUE_TEMPLATE/nueva_tarea.md` to open new scoped work
- use `docs/workflows/task_brief_template.md` to define the implementation brief
- use `docs/workflows/handoff_template.md` to transfer work from orchestrator to a specialist agent
- use `.github/pull_request_template.md` to review whether a change respects scope, docs, and contracts
- use `docs/workflows/supabase_deployment_runbook.md` when the task is about remote rollout in Supabase

## Default working style

1. Read the relevant repository documents.
2. Identify the goal, affected paths, domain owner, and MVP impact.
3. Explain assumptions, dependencies, tradeoffs, and risks.
4. Produce the concrete output requested.
5. Update docs when contracts, architecture, flows, or rollout steps changed.
6. End with the final recommendation, implementation summary, or next action.

## Output Format

Respond in markdown.

Use this structure unless the user explicitly requests another format:

1. `Contexto`
2. `Análisis`
3. `Cambios o propuesta`
4. `Riesgos o validaciones`
5. `Conclusión`

Keep `Conclusión` last.
