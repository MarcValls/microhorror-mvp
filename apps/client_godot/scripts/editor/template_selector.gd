extends Control

## TemplateSelectorScreen — muestra el catálogo de plantillas disponibles.
## El jugador elige una plantilla para crear un proyecto nuevo.

@onready var template_list: VBoxContainer = $ScrollContainer/TemplateList
@onready var btn_back: Button = $Header/BtnBack

const TEMPLATE_CARD_SCENE := preload("res://scenes/editor/template_card.tscn")


func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	_populate_templates()


func _populate_templates() -> void:
	for child in template_list.get_children():
		child.queue_free()
	for template in ContentCatalog.templates:
		var card := TEMPLATE_CARD_SCENE.instantiate()
		card.setup(template)
		card.selected.connect(_on_template_selected.bind(template))
		template_list.add_child(card)


func _on_template_selected(template: TemplateData) -> void:
	var project := ProjectData.new()
	project.template_key = template.key
	project.threat_key = template.default_threat
	project.atmosphere_key = template.default_atmosphere_preset
	if template.default_endings.size() > 0:
		project.ending_payload = {"endings": Array(template.default_endings)}
	GameState.set_active_project(project)
	_save_new_project(project)


func _save_new_project(project: ProjectData) -> void:
	var result := await BackendClient.create_project({
		"title": "Nueva experiencia",
		"template_id": project.template_key,
		"threat_id": project.threat_key,
		"atmosphere_preset_id": project.atmosphere_key,
		"status": "draft",
	})
	if result.code >= 200 and result.code < 300:
		# Supabase PostgREST returns an array on INSERT; handle both array and dict
		var data: Variant = result.data
		if data is Array and data.size() > 0:
			project.id = (data[0] as Dictionary).get("id", "")
		elif data is Dictionary:
			project.id = data.get("id", "")
	EventBus.emit_signal("project_created", project.id)
	EventBus.emit_signal("screen_transition_requested", "res://scenes/editor/project_editor.tscn")


func _on_back_pressed() -> void:
	EventBus.emit_signal("screen_transition_requested", "res://scenes/main_menu/main_menu.tscn")
