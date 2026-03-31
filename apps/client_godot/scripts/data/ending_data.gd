class_name EndingData
extends Resource

## Definición de un final de experiencia. Cargada desde el catálogo data-driven.

@export var id: String = ""
@export var key: String = ""
@export var display_name: String = ""
@export var resolution_type: String = "success"  # success | failure
@export var condition_type: String = ""
@export var title_key: String = ""
@export var body_key: String = ""
@export var show_survived_time: bool = true
@export var cta_share: bool = true
@export var cta_replay: bool = true
