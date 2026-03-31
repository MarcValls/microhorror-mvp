extends Node

## SceneManager — autoload global
## Escucha la señal screen_transition_requested del EventBus y gestiona
## las transiciones de escena de forma centralizada.

func _ready() -> void:
	EventBus.screen_transition_requested.connect(_on_transition_requested)


func _on_transition_requested(target_scene: String) -> void:
	var error := get_tree().change_scene_to_file(target_scene)
	if error != OK:
		push_error("SceneManager: no se pudo cargar la escena '%s' (error %d)" % [target_scene, error])
