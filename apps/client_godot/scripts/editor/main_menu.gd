extends Control

## MainMenu — pantalla inicial de la app.
## CTA principal: Jugar (descubrir / abrir enlace) y Crear (editor).

@onready var btn_play: Button = $VBox/BtnPlay
@onready var btn_create: Button = $VBox/BtnCreate
@onready var btn_login: Button = $VBox/BtnLogin


func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_create.pressed.connect(_on_create_pressed)
	btn_login.pressed.connect(_on_login_pressed)
	_refresh_auth_state()


func _refresh_auth_state() -> void:
	btn_login.visible = GameState.current_user == null and not GameState.is_guest


func _on_play_pressed() -> void:
	EventBus.emit_signal("screen_transition_requested", "res://scenes/ui/discover.tscn")


func _on_create_pressed() -> void:
	if GameState.current_user == null and not GameState.is_guest:
		EventBus.emit_signal("screen_transition_requested", "res://scenes/ui/login.tscn")
		return
	EventBus.emit_signal("screen_transition_requested", "res://scenes/editor/template_selector.tscn")


func _on_login_pressed() -> void:
	EventBus.emit_signal("screen_transition_requested", "res://scenes/ui/login.tscn")
