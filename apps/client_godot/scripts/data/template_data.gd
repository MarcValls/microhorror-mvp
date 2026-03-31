class_name TemplateData
extends Resource

## Definición de una plantilla de experiencia. Cargada desde el catálogo data-driven.

@export var id: String = ""
@export var key: String = ""
@export var display_name: String = ""
@export var mood: String = ""
@export var estimated_duration_minutes: int = 5
@export var difficulty: String = "normal"
@export var environment: String = ""
@export var lighting_preset: String = ""
@export var audio_ambience: String = ""
@export var starting_room: String = ""
@export var rooms: PackedStringArray = []
@export var fog_density: float = 0.3
@export var default_atmosphere_preset: String = ""
@export var allowed_threats: PackedStringArray = []
@export var allowed_events: PackedStringArray = []
@export var max_events: int = 5
@export var default_threat: String = ""
@export var default_endings: PackedStringArray = []
