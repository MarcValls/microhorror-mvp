extends Node

## GameState — autoload global
## Mantiene el estado de sesión del usuario y del proyecto activo.

signal project_changed(project: ProjectData)
signal user_changed(user: UserData)

var current_user: UserData = null
var active_project: ProjectData = null
var is_guest: bool = false


func set_user(user: UserData) -> void:
	current_user = user
	is_guest = false
	emit_signal("user_changed", user)


func set_guest_mode() -> void:
	current_user = null
	is_guest = true


func set_active_project(project: ProjectData) -> void:
	active_project = project
	emit_signal("project_changed", project)


func clear_active_project() -> void:
	active_project = null
