extends Control

## ProjectEditor — editor por capas del MVP.
## Contiene 5 paneles (atmósfera, amenaza, eventos, historia, finales)
## más controles de guardado, playtest y publicación.

@onready var tab_container: TabContainer = $MainLayout/TabContainer
@onready var header_title: LineEdit = $MainLayout/Header/TitleField
@onready var btn_back: Button = $MainLayout/Header/BtnBack
@onready var btn_save: Button = $MainLayout/Footer/BtnSave
@onready var btn_playtest: Button = $MainLayout/Footer/BtnPlaytest
@onready var btn_publish: Button = $MainLayout/Footer/BtnPublish
@onready var lbl_status: Label = $MainLayout/Footer/LblStatus

# Panel references (loaded when tabs are ready)
@onready var atmosphere_panel = $MainLayout/TabContainer/Atmósfera
@onready var threat_panel = $MainLayout/TabContainer/Amenaza
@onready var events_panel = $MainLayout/TabContainer/Eventos
@onready var story_panel = $MainLayout/TabContainer/Historia
@onready var endings_panel = $MainLayout/TabContainer/Finales

var _autosave_timer: Timer
const AUTOSAVE_INTERVAL := 30.0


func _ready() -> void:
	var project := GameState.active_project
	if project == null:
		push_error("ProjectEditor: no hay proyecto activo en GameState")
		return

	header_title.text = project.title
	header_title.text_changed.connect(func(t): GameState.active_project.title = t)

	btn_back.pressed.connect(_on_back_pressed)
	btn_save.pressed.connect(_on_save_pressed)
	btn_playtest.pressed.connect(_on_playtest_pressed)
	btn_publish.pressed.connect(_on_publish_pressed)

	_setup_autosave()
	_refresh_status()


func _setup_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_save_pressed)
	add_child(_autosave_timer)


func _refresh_status() -> void:
	var project := GameState.active_project
	if project == null:
		return
	match project.status:
		"draft":
			lbl_status.text = "Borrador"
			btn_publish.disabled = false
		"published":
			lbl_status.text = "Publicado"
			btn_publish.disabled = true
		_:
			lbl_status.text = project.status


func _on_back_pressed() -> void:
	EventBus.emit_signal("screen_transition_requested", "res://scenes/main_menu/main_menu.tscn")


func _on_save_pressed() -> void:
	var project := GameState.active_project
	if project == null or project.id.is_empty():
		return
	var payload := {
		"title": project.title,
		"threat_id": project.threat_key,
		"atmosphere_preset_id": project.atmosphere_key,
		"story_payload": project.story_payload,
		"event_payload": project.event_payload,
		"ending_payload": project.ending_payload,
		"status": project.status,
	}
	lbl_status.text = "Guardando…"
	var result := await BackendClient.save_draft(project.id, payload)
	if result.code >= 200 and result.code < 300:
		lbl_status.text = "Guardado"
		EventBus.emit_signal("project_draft_saved", project.id)
	else:
		lbl_status.text = "Error al guardar"


func _on_playtest_pressed() -> void:
	var project := GameState.active_project
	if project == null:
		return
	EventBus.emit_signal("playtest_started", project.id)
	# Lanzar runtime en modo playtest
	var runtime: Node = load("res://scenes/runtime/runtime_session.tscn").instantiate()
	GameState.set_active_project(project)
	get_tree().root.add_child(runtime)
	runtime.start_as_playtest()
	get_tree().current_scene = runtime


func _on_publish_pressed() -> void:
	var project := GameState.active_project
	if project == null or project.id.is_empty():
		return
	if project.title.strip_edges().is_empty():
		lbl_status.text = "El proyecto necesita un título"
		return
	lbl_status.text = "Publicando…"
	btn_publish.disabled = true
	var result := await BackendClient.publish_project(project.id)
	if result.code == 200:
		project.status = "published"
		project.publish_slug = result.data.get("slug", "")
		GameState.set_active_project(project)
		EventBus.emit_signal("project_published", project.id, project.publish_slug)
		lbl_status.text = "Publicado · " + project.publish_slug
	else:
		lbl_status.text = "Error al publicar"
		btn_publish.disabled = false
