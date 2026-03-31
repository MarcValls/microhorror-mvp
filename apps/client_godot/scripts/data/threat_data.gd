class_name ThreatData
extends Resource

## Definición de una amenaza. Cargada desde el catálogo data-driven.

@export var id: String = ""
@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var detection_radius: float = 6.0
@export var chase_speed: float = 3.5
@export var idle_speed: float = 1.2
@export var visibility: String = "partial"  # none | partial | full
@export var aggression_curve: String = "escalating"
@export var special_ability: String = ""
@export var audio_cue_idle: String = ""
@export var audio_cue_chase: String = ""
@export var patience_seconds: float = 12.0
@export var can_open_doors: bool = false
