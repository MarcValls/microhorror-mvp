extends PanelContainer

## TemplateCard — tarjeta de selección de plantilla.
## Muestra nombre, mood, duración y dificultad de una TemplateData.

signal selected

@onready var lbl_name: Label = $VBox/LblName
@onready var lbl_mood: Label = $VBox/LblMood
@onready var lbl_meta: Label = $VBox/LblMeta
@onready var btn_select: Button = $VBox/BtnSelect


func setup(template: TemplateData) -> void:
	lbl_name.text = template.display_name
	lbl_mood.text = template.mood
	lbl_meta.text = "%d min  ·  %s" % [template.estimated_duration_minutes, template.difficulty]
	btn_select.pressed.connect(func(): emit_signal("selected"))
