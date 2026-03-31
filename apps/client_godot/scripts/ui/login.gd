extends Control

## LoginScreen — acceso con fricción mínima.
## Soporta login anónimo (modo invitado) o con email/contraseña.

@onready var email_field: LineEdit = $VBox/EmailField
@onready var password_field: LineEdit = $VBox/PasswordField
@onready var btn_login: Button = $VBox/BtnLogin
@onready var btn_guest: Button = $VBox/BtnGuest
@onready var lbl_error: Label = $VBox/LblError

var _login_start_time: float = 0.0


func _ready() -> void:
	lbl_error.visible = false
	btn_login.pressed.connect(_on_login_pressed)
	btn_guest.pressed.connect(_on_guest_pressed)
	BackendClient.ingest_event("onboarding_started", {
		"source": "login_screen",
		"device_class": _detect_device_class(),
	})
	_login_start_time = Time.get_unix_time_from_system()


func _on_login_pressed() -> void:
	lbl_error.visible = false
	btn_login.disabled = true
	var email := email_field.text.strip_edges()
	var password := password_field.text
	if email.is_empty() or password.is_empty():
		_show_error("Email y contraseña son obligatorios.")
		btn_login.disabled = false
		return
	var result := await BackendClient.sign_in_with_email(email, password)
	btn_login.disabled = false
	if result.code >= 200 and result.code < 300:
		var token: String = result.data.get("access_token", "")
		BackendClient.set_access_token(token)
		var elapsed := int(Time.get_unix_time_from_system() - _login_start_time)
		BackendClient.ingest_event("signup_completed", {
			"method": "email",
			"time_to_complete_seconds": elapsed,
		})
		EventBus.emit_signal("screen_transition_requested", "res://scenes/main_menu/main_menu.tscn")
	else:
		_show_error("Credenciales incorrectas. Inténtalo de nuevo.")


func _on_guest_pressed() -> void:
	GameState.set_guest_mode()
	EventBus.emit_signal("screen_transition_requested", "res://scenes/editor/template_selector.tscn")


func _show_error(msg: String) -> void:
	lbl_error.text = msg
	lbl_error.visible = true


func _detect_device_class() -> String:
	var os_name := OS.get_name()
	if os_name in ["Android", "iOS"]:
		return "mobile"
	if OS.has_feature("mobile"):
		return "mobile"
	return "desktop"
