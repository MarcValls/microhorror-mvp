# Data model inicial

## Principios
- modelo centrado en proyectos y sesiones
- contenido reutilizable definido por catálogo (JSON en el cliente, no tablas DB)
- soporte para métricas agregadas sin complejidad excesiva

## Capas del modelo

### Capa 1: Base de datos (Supabase — esquema canónico: `20260331_0001_init_schema.sql`)

Las siguientes tablas viven en Supabase. Los identificadores de template/threat/atmosphere
se almacenan como claves de texto (no UUID FK), alineados con los keys del catálogo JSON.

#### UserProfile (`profiles`)
- user_id (PK, referencia auth.users)
- handle
- display_name
- avatar_url
- bio
- social_links
- is_public
- plan
- created_at
- updated_at

#### Project (`projects`)
- id
- owner_id
- title
- subtitle
- template_id (text key, e.g. `abandoned_house`)
- threat_id (text key, e.g. `shadow_figure`)
- atmosphere_preset_id (text key, e.g. `oppressive`)
- story_payload
- event_payload
- ending_payload
- visibility
- publish_slug
- status
- allow_remix
- created_at
- updated_at
- published_at

#### PlaySession (`play_sessions`)
- id
- project_id
- player_id_nullable
- started_at
- completed_at
- outcome
- ending_id (text key)
- survived_seconds
- shared_result
- created_at

#### GeneratedAsset (`generated_assets`)
- id
- project_id
- asset_type (`teaser` | `thumbnail_square` | `thumbnail_vertical` | `other`)
- storage_path
- generation_status (`pending` | `ready` | `failed`)
- created_at

#### FeatureEntitlement (`feature_entitlements`)
- id
- plan_key
- feature_key
- is_enabled
- limits_json

---

### Capa 2: Catálogo de contenido (JSON del cliente — `apps/client_godot/resources/`)

Estas entidades no tienen tabla en la base de datos. Viven en archivos JSON dentro
del proyecto Godot (`res://resources/`) y son cargadas por `ContentCatalog` autoload.
La fuente de verdad canónica está en `/content/` (raíz del repo).

#### TemplateDefinition
- id (e.g. `tpl_abandoned_house`)
- key (e.g. `abandoned_house`) — identificador estable
- display_name
- mood
- estimated_duration_minutes
- difficulty
- scene_config (environment, lighting_preset, audio_ambience, rooms, fog_density, default_atmosphere_preset)
- allowed_threats (array de keys)
- allowed_events (array de keys)
- max_events
- default_threat (key)
- default_endings (array de keys)

#### ThreatDefinition
- id
- key — identificador estable
- display_name
- description
- behavior_config (detection_radius, chase_speed, visibility, aggression_curve, etc.)

#### EventDefinition
- id
- key — identificador estable
- display_name
- event_type
- timing_rules
- payload_schema

#### EndingDefinition
- id
- key — identificador estable
- display_name
- resolution_type (`success` | `failure`)
- conditions_schema
- result_screen (title_key, body_key, show_survived_time, cta_share, cta_replay)

#### AtmospherePreset
- id (e.g. `atm_oppressive`)
- key (e.g. `oppressive`) — identificador estable
- display_name
- description
- visual_config (color_grade, vignette_intensity, grain_intensity, blur_edges)
- audio_config (reverb_preset, low_pass_cutoff, ambient_volume)

---

## Relaciones mínimas
- un UserProfile puede tener muchos Project
- un Project puede tener muchas PlaySession
- un Project puede tener muchos GeneratedAsset
- un Project referencia una TemplateDefinition (por key)
- un Project puede usar varias EventDefinition mediante payload configurable

## Estados recomendados para Project
- draft
- ready_to_publish
- published
- archived
