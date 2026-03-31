extends Node3D

## RuntimeSession — escena base del juego en primera persona.
## Carga la configuración del proyecto activo y orquesta amenaza, eventos y estado de sesión.

@onready var session_timer: Timer = $SessionTimer
@onready var threat_spawner: Node3D = $ThreatSpawner
@onready var event_director: Node = $EventDirector

var project: ProjectData
var template: TemplateData
var threat: ThreatData
var session_id: String = ""
var survived_seconds: int = 0
var _survived_float: float = 0.0
var _is_playtest: bool = false
var _playtest_reported: bool = false


func _ready() -> void:
	project = GameState.active_project
	if project == null:
		push_error("RuntimeSession: no hay proyecto activo en GameState")
		return

	template = ContentCatalog.get_template(project.template_key)
	threat = ContentCatalog.get_threat(project.threat_key)

	_setup_environment()
	_start_session()


func start_as_playtest() -> void:
	_is_playtest = true


func _setup_environment() -> void:
	if template == null:
		return
	# Configuración data-driven: niebla, iluminación y ambiente se cargan
	# desde el template; el runtime no tiene lógica por plantilla.
	var env := Environment.new()
	$WorldEnvironment.environment = env


func _start_session() -> void:
	session_timer.start()
	EventBus.emit_signal("game_session_started", project.id, _is_playtest)


func _process(delta: float) -> void:
	_survived_float += delta
	survived_seconds = int(_survived_float)


func _exit_tree() -> void:
	if _is_playtest and not _playtest_reported and project != null:
		_playtest_reported = true
		EventBus.emit_signal("playtest_ended", project.id, "cancelled", survived_seconds)


func trigger_ending(ending_key: String) -> void:
	session_timer.stop()
	var ending: EndingData = ContentCatalog.get_ending(ending_key)
	if ending == null:
		return
	if _is_playtest:
		_playtest_reported = true
		EventBus.emit_signal("playtest_ended", project.id, ending.resolution_type, survived_seconds)
	EventBus.emit_signal("ending_reached", project.id, ending_key, survived_seconds, _is_playtest)
	EventBus.emit_signal(
		"game_session_completed",
		project.id,
		ending.resolution_type,
		survived_seconds,
		ending_key,
		_is_playtest
	)
	_show_result_screen(ending)


func _show_result_screen(ending: EndingData) -> void:
	EventBus.emit_signal("screen_transition_requested", "res://scenes/ui/result_screen.tscn")
