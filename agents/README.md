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
  - Use for Godot 5.4.1 client work, scene architecture, scripts, runtime systems, and guided creation UI.

- `agents/supabase_backend_system_prompt.md`
  - Use for schema design, migrations, RLS, storage, functions, publication flow, and analytics.

- `agents/content_system_prompt.md`
  - Use for templates, threats, events, endings, presets, payload schemas, and content validation.

## Recommended default

If the task is unclear or touches several areas, start with `agents/orchestrator_system_prompt.md`.
