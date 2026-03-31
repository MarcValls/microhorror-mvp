class_name AtmosphereData
extends Resource

## Preset de atmósfera visual y sonora. Cargada desde el catálogo data-driven.

@export var id: String = ""
@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
# Visual
@export var color_grade: String = ""
@export var vignette_intensity: float = 0.4
@export var grain_intensity: float = 0.3
@export var blur_edges: bool = false
# Audio
@export var reverb_preset: String = ""
@export var low_pass_cutoff: float = 1000.0
@export var ambient_volume: float = 0.7
