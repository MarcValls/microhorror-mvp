class_name ProjectData
extends Resource

## Estado de un proyecto de usuario en memoria (borrador o publicado).

@export var id: String = ""
@export var owner_id: String = ""
@export var title: String = ""
@export var subtitle: String = ""
@export var template_key: String = ""
@export var threat_key: String = ""
@export var atmosphere_key: String = ""
@export var story_payload: Dictionary = {}
@export var event_payload: Array[Dictionary] = []
@export var ending_payload: Dictionary = {}
@export var visibility: String = "private"
@export var publish_slug: String = ""
@export var status: String = "draft"  # draft | ready_to_publish | published | archived
@export var allow_remix: bool = false
@export var published_at: String = ""
