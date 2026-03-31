extends Node

## AnalyticsTracker — autoload global
## Conecta las señales del EventBus con BackendClient.ingest_event de forma desacoplada.
## Los eventos se envían en background sin bloquear el flujo del juego.

func _ready() -> void:
	EventBus.project_created.connect(_on_project_created)
	EventBus.playtest_started.connect(_on_playtest_started)
	EventBus.playtest_ended.connect(_on_playtest_ended)
	EventBus.project_published.connect(_on_project_published)
	EventBus.game_session_started.connect(_on_game_session_started)
	EventBus.game_session_completed.connect(_on_game_session_completed)
	EventBus.ending_reached.connect(_on_ending_reached)
	EventBus.result_shared.connect(_on_result_shared)


# --- Creación ---

func _on_project_created(project_id: String) -> void:
	var project: ProjectData = GameState.active_project
	BackendClient.ingest_event("project_created", {
		"template_id": project.template_key if project else "",
		"source_screen": "template_selector",
	}, project_id)


func _on_playtest_started(project_id: String) -> void:
	var project: ProjectData = GameState.active_project
	BackendClient.ingest_event("playtest_started", {
		"template_id": project.template_key if project else "",
	}, project_id)


func _on_playtest_ended(project_id: String, outcome: String, duration_seconds: int) -> void:
	BackendClient.ingest_event("playtest_completed", {
		"outcome": outcome,
		"duration_seconds": duration_seconds,
	}, project_id)


func _on_project_published(project_id: String, _slug: String) -> void:
	var project: ProjectData = GameState.active_project
	BackendClient.ingest_event("project_published", {
		"template_id": project.template_key if project else "",
		"visibility": project.visibility if project else "public",
		"teaser_generated": false,
	}, project_id)


# --- Juego ---

func _on_game_session_started(project_id: String, is_playtest: bool) -> void:
	if is_playtest:
		return
	BackendClient.ingest_event("game_session_started", {
		"entrypoint": "direct",
		"player_type": "authenticated" if GameState.current_user != null else "anonymous",
	}, project_id)


func _on_game_session_completed(project_id: String, outcome: String, survived_seconds: int, ending_id: String, is_playtest: bool) -> void:
	if is_playtest:
		return
	BackendClient.ingest_event("game_session_completed", {
		"completed": outcome == "success",
		"ending_id": ending_id,
		"survived_seconds": survived_seconds,
	}, project_id)


func _on_ending_reached(project_id: String, ending_id: String, survived_seconds: int, is_playtest: bool) -> void:
	if is_playtest:
		return
	BackendClient.ingest_event("ending_reached", {
		"ending_id": ending_id,
		"survived_seconds": survived_seconds,
	}, project_id)


# --- Distribución ---

func _on_result_shared(project_id: String, channel: String) -> void:
	var project: ProjectData = GameState.active_project
	BackendClient.ingest_event("result_shared", {
		"channel": channel,
		"ending_id": "",
	}, project_id)
