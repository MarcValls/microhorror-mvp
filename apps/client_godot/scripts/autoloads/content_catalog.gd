extends Node

## ContentCatalog — autoload global
## Carga y expone los catálogos de contenido (plantillas, amenazas, eventos, finales, atmósferas).
## Los archivos JSON viven en res://resources/ y se cargan una única vez al inicio.

const CATALOG_PATHS := {
	"templates": "res://resources/templates/",
	"threats": "res://resources/threats/",
	"events": "res://resources/events/",
	"endings": "res://resources/endings/",
	"atmosphere": "res://resources/atmosphere/",
}

var templates: Array[TemplateData] = []
var threats: Array[ThreatData] = []
var events: Array[EventData] = []
var endings: Array[EndingData] = []
var atmosphere_presets: Array[AtmosphereData] = []


func _ready() -> void:
	_load_json_catalog("templates", templates, _parse_template)
	_load_json_catalog("threats", threats, _parse_threat)
	_load_json_catalog("events", events, _parse_event)
	_load_json_catalog("endings", endings, _parse_ending)
	_load_json_catalog("atmosphere", atmosphere_presets, _parse_atmosphere)


func get_template(key: String) -> TemplateData:
	return _find_by_key(templates, key)


func get_threat(key: String) -> ThreatData:
	return _find_by_key(threats, key)


func get_event(key: String) -> EventData:
	return _find_by_key(events, key)


func get_ending(key: String) -> EndingData:
	return _find_by_key(endings, key)


func get_atmosphere(key: String) -> AtmosphereData:
	return _find_by_key(atmosphere_presets, key)


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------

func _load_json_catalog(catalog_key: String, target: Array, parser: Callable) -> void:
	var dir := DirAccess.open(CATALOG_PATHS[catalog_key])
	if dir == null:
		push_warning("ContentCatalog: no se pudo abrir " + CATALOG_PATHS[catalog_key])
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var path := CATALOG_PATHS[catalog_key] + file_name
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				push_warning("ContentCatalog: no se pudo leer " + path)
			else:
				var data: Variant = JSON.parse_string(file.get_as_text())
				if data is Dictionary:
					var resource: Resource = parser.call(data)
					if resource != null:
						target.append(resource)
				else:
					push_warning("ContentCatalog: JSON inválido en " + path)
		file_name = dir.get_next()


func _find_by_key(catalog: Array, key: String) -> Resource:
	for item in catalog:
		if item.key == key:
			return item
	return null


# ---------------------------------------------------------------------------
# Parsers por tipo
# ---------------------------------------------------------------------------

func _parse_template(d: Dictionary) -> TemplateData:
	var r := TemplateData.new()
	r.id = d.get("id", "")
	r.key = d.get("key", "")
	r.display_name = d.get("display_name", "")
	r.mood = d.get("mood", "")
	r.estimated_duration_minutes = d.get("estimated_duration_minutes", 5)
	r.difficulty = d.get("difficulty", "normal")
	var sc: Dictionary = d.get("scene_config", {})
	r.environment = sc.get("environment", "")
	r.lighting_preset = sc.get("lighting_preset", "")
	r.audio_ambience = sc.get("audio_ambience", "")
	r.starting_room = sc.get("starting_room", "")
	r.rooms = PackedStringArray(sc.get("rooms", []))
	r.fog_density = sc.get("fog_density", 0.3)
	r.default_atmosphere_preset = sc.get("default_atmosphere_preset", "")
	r.allowed_threats = PackedStringArray(d.get("allowed_threats", []))
	r.allowed_events = PackedStringArray(d.get("allowed_events", []))
	r.max_events = d.get("max_events", 5)
	r.default_threat = d.get("default_threat", "")
	r.default_endings = PackedStringArray(d.get("default_endings", []))
	return r


func _parse_threat(d: Dictionary) -> ThreatData:
	var r := ThreatData.new()
	r.id = d.get("id", "")
	r.key = d.get("key", "")
	r.display_name = d.get("display_name", "")
	r.description = d.get("description", "")
	var bc: Dictionary = d.get("behavior_config", {})
	r.detection_radius = bc.get("detection_radius", 6.0)
	r.chase_speed = bc.get("chase_speed", 3.5)
	r.idle_speed = bc.get("idle_speed", 1.2)
	r.visibility = bc.get("visibility", "partial")
	r.aggression_curve = bc.get("aggression_curve", "escalating")
	r.special_ability = bc.get("special_ability", "")
	r.audio_cue_idle = bc.get("audio_cue_idle", "")
	r.audio_cue_chase = bc.get("audio_cue_chase", "")
	r.patience_seconds = bc.get("patience_seconds", 12.0)
	r.can_open_doors = bc.get("can_open_doors", false)
	return r


func _parse_event(d: Dictionary) -> EventData:
	var r := EventData.new()
	r.id = d.get("id", "")
	r.key = d.get("key", "")
	r.display_name = d.get("display_name", "")
	r.event_type = d.get("event_type", "")
	var tr: Dictionary = d.get("timing_rules", {})
	r.trigger = tr.get("trigger", "time_elapsed")
	r.min_interval_seconds = tr.get("min_interval_seconds", 30.0)
	r.can_repeat = tr.get("can_repeat", true)
	r.max_occurrences = tr.get("max_occurrences", -1)
	r.payload_schema = d.get("payload_schema", {})
	return r


func _parse_ending(d: Dictionary) -> EndingData:
	var r := EndingData.new()
	r.id = d.get("id", "")
	r.key = d.get("key", "")
	r.display_name = d.get("display_name", "")
	r.resolution_type = d.get("resolution_type", "success")
	var cs: Dictionary = d.get("conditions_schema", {})
	r.condition_type = cs.get("type", "")
	var rs: Dictionary = d.get("result_screen", {})
	r.title_key = rs.get("title_key", "")
	r.body_key = rs.get("body_key", "")
	r.show_survived_time = rs.get("show_survived_time", true)
	r.cta_share = rs.get("cta_share", true)
	r.cta_replay = rs.get("cta_replay", true)
	return r


func _parse_atmosphere(d: Dictionary) -> AtmosphereData:
	var r := AtmosphereData.new()
	r.id = d.get("id", "")
	r.key = d.get("key", "")
	r.display_name = d.get("display_name", "")
	r.description = d.get("description", "")
	var vc: Dictionary = d.get("visual_config", {})
	r.color_grade = vc.get("color_grade", "")
	r.vignette_intensity = vc.get("vignette_intensity", 0.4)
	r.grain_intensity = vc.get("grain_intensity", 0.3)
	r.blur_edges = vc.get("blur_edges", false)
	var ac: Dictionary = d.get("audio_config", {})
	r.reverb_preset = ac.get("reverb_preset", "")
	r.low_pass_cutoff = ac.get("low_pass_cutoff", 1000.0)
	r.ambient_volume = ac.get("ambient_volume", 0.7)
	return r

