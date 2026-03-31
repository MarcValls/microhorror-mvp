class_name EventData
extends Resource

## Definición de un evento de ambiente. Cargada desde el catálogo data-driven.

@export var id: String = ""
@export var key: String = ""
@export var display_name: String = ""
@export var event_type: String = ""  # environmental | audio | visual
@export var trigger: String = "time_elapsed"
@export var min_interval_seconds: float = 30.0
@export var can_repeat: bool = true
@export var max_occurrences: int = -1  # -1 = ilimitado
@export var payload_schema: Dictionary = {}
