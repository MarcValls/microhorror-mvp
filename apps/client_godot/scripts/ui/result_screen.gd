extends Control

## ResultScreen — pantalla final tras completar o fallar una sesión de juego.
## Muestra el final alcanzado, el tiempo sobrevivido y CTAs de compartir y rejugar.

@onready var lbl_title: Label = $VBox/LblTitle
@onready var lbl_body: Label = $VBox/LblBody
@onready var lbl_time: Label = $VBox/LblTime
@onready var btn_share: Button = $VBox/BtnShare
@onready var btn_replay: Button = $VBox/BtnReplay
@onready var btn_back: Button = $VBox/BtnBack

var _project_id: String = ""
var _ending: EndingData = null
var _survived_seconds: int = 0


func _ready() -> void:
	btn_share.pressed.connect(_on_share_pressed)
	btn_replay.pressed.connect(_on_replay_pressed)
	btn_back.pressed.connect(_on_back_pressed)

	# Cargar el final activo desde GameState (set por RuntimeSession antes de la transición)
	var ending_key := GameState.active_ending_key
	if not ending_key.is_empty():
		_ending = ContentCatalog.get_ending(ending_key)
	_project_id = GameState.active_project.id if GameState.active_project else ""
	_survived_seconds = GameState.active_survived_seconds
	_refresh_ui()


func setup(project_id: String, ending: EndingData, survived_seconds: int) -> void:
	_project_id = project_id
	_ending = ending
	_survived_seconds = survived_seconds
	_refresh_ui()


func _refresh_ui() -> void:
	if _ending != null:
		# display_name is the user-facing title; body is resolved via localization (MVP: use display_name as fallback)
		lbl_title.text = _ending.display_name
		lbl_body.text = tr(_ending.body_key) if TranslationServer.has_message(_ending.body_key) else _ending.display_name
		btn_share.visible = _ending.cta_share
		btn_replay.visible = _ending.cta_replay
	else:
		lbl_title.text = "Fin"
		lbl_body.text = ""

	if _survived_seconds > 0:
		var mins := _survived_seconds / 60
		var secs := _survived_seconds % 60
		lbl_time.text = "Sobreviviste %d:%02d" % [mins, secs]
		lbl_time.visible = true
	else:
		lbl_time.visible = false


func _on_share_pressed() -> void:
	# En móvil se usa el API nativo de compartir
	if OS.has_feature("mobile"):
		var share_text := "¡Jugué a microhorror! ¿Te atreves tú? #microhorror"
		OS.shell_open("https://microhorror.app/play/%s" % _project_id)
	EventBus.emit_signal("result_shared", _project_id, "native_share")


func _on_replay_pressed() -> void:
	EventBus.emit_signal("screen_transition_requested", "res://scenes/runtime/runtime_session.tscn")


func _on_back_pressed() -> void:
	EventBus.emit_signal("screen_transition_requested", "res://scenes/main_menu/main_menu.tscn")
