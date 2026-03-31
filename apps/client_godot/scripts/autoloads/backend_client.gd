extends Node

## BackendClient — autoload global
## Abstracción sobre la API de Supabase: auth, proyectos, publicación e ingesta de eventos.

const SUPABASE_URL_KEY := "SUPABASE_URL"
const SUPABASE_ANON_KEY_KEY := "SUPABASE_ANON_KEY"

var _supabase_url: String = ""
var _anon_key: String = ""
var _access_token: String = ""


func _ready() -> void:
	# Cargar configuración desde variables de entorno o un archivo local no versionado
	_supabase_url = OS.get_environment(SUPABASE_URL_KEY)
	_anon_key = OS.get_environment(SUPABASE_ANON_KEY_KEY)


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

func sign_in_anonymous() -> Dictionary:
	# Supabase anon auth: POST /auth/v1/signup with no credentials
	return await _post("/auth/v1/signup", {
		"email": "",
		"password": "",
		"gotrue_meta_security": {},
	})


func sign_in_with_email(email: String, password: String) -> Dictionary:
	return await _post("/auth/v1/token?grant_type=password", {
		"email": email,
		"password": password,
	})


func set_access_token(token: String) -> void:
	_access_token = token


# ---------------------------------------------------------------------------
# Proyectos
# ---------------------------------------------------------------------------

func create_project(payload: Dictionary) -> Dictionary:
	return await _post("/rest/v1/projects", payload)


func save_draft(project_id: String, payload: Dictionary) -> Dictionary:
	return await _patch("/rest/v1/projects?id=eq." + project_id, payload)


func publish_project(project_id: String) -> Dictionary:
	return await _post("/functions/v1/publish_project", {"project_id": project_id})


# ---------------------------------------------------------------------------
# Analítica
# ---------------------------------------------------------------------------

func ingest_event(event_name: String, properties: Dictionary = {}, project_id: String = "") -> void:
	var body := {"event_name": event_name, "properties": properties}
	if project_id != "":
		body["project_id"] = project_id
	await _post("/functions/v1/ingest_event", body)


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

func _headers() -> PackedStringArray:
	var h := PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + _anon_key,
	])
	if _access_token != "":
		h.append("Authorization: Bearer " + _access_token)
	return h


func _post(path: String, body: Dictionary) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, path, body)


func _patch(path: String, body: Dictionary) -> Dictionary:
	return await _request(HTTPClient.METHOD_PATCH, path, body)


func _request(method: int, path: String, body: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var url := _supabase_url + path
	var json_body := JSON.stringify(body)
	http.request(url, _headers(), method, json_body)
	var result: Array = await http.request_completed
	http.queue_free()
	var response_code: int = result[1]
	var response_body: String = result[3].get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(response_body)
	return {
		"code": response_code,
		"data": parsed if parsed != null else {},
	}
