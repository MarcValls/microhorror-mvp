extends Node

## EventBus — autoload global
## Bus de señales desacoplado para comunicación entre sistemas sin dependencias directas.

# --- Ciclo de creación ---
signal project_created(project_id: String)
signal project_draft_saved(project_id: String)
signal playtest_started(project_id: String)
signal playtest_ended(project_id: String, outcome: String)
signal project_published(project_id: String, slug: String)

# --- Ciclo de juego ---
signal game_session_started(project_id: String)
signal game_session_completed(project_id: String, outcome: String, survived_seconds: int)
signal ending_reached(ending_id: String)
signal result_shared(project_id: String, channel: String)

# --- UI ---
signal screen_transition_requested(target_scene: String)
signal loading_started(message: String)
signal loading_finished()
signal error_shown(message: String)
