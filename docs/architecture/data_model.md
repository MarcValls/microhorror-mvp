# Data model inicial

## Principios
- modelo centrado en proyectos y sesiones
- contenido reutilizable definido por catálogo
- soporte para métricas agregadas sin complejidad excesiva

## Entidades principales

### User
- id
- handle
- display_name
- avatar_url
- created_at
- plan

### Profile
- user_id
- bio
- social_links
- is_public

### Project
- id
- owner_id
- title
- subtitle
- template_id
- threat_id
- atmosphere_preset_id
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

### TemplateDefinition
- id
- key
- display_name
- mood
- estimated_duration_minutes
- difficulty
- scene_config

### ThreatDefinition
- id
- key
- display_name
- behavior_config

### EventDefinition
- id
- key
- display_name
- event_type
- timing_rules
- payload_schema

### EndingDefinition
- id
- key
- display_name
- resolution_type
- conditions_schema

### PlaySession
- id
- project_id
- player_id_nullable
- started_at
- completed_at
- outcome
- ending_id_nullable
- survived_seconds
- shared_result

### GeneratedAsset
- id
- project_id
- asset_type
- storage_path
- generation_status
- created_at

### FeatureEntitlement
- id
- plan_key
- feature_key
- is_enabled
- limits_json

## Relaciones mínimas
- un User puede tener muchos Project
- un Project puede tener muchas PlaySession
- un Project puede tener muchos GeneratedAsset
- un Project referencia una TemplateDefinition
- un Project puede usar varias EventDefinition mediante payload configurable

## Estados recomendados para Project
- draft
- ready_to_publish
- published
- archived
