-- Seed: catálogo inicial de contenido para el MVP (COMPATIBILIDAD CON ESQUEMA 001)
-- NOTA: Este archivo pertenece al esquema 001_initial_schema.sql (DEPRECADO).
-- El esquema canónico 20260331_0001_init_schema.sql NO tiene tablas de catálogo
-- (template_definitions, threat_definitions, etc.): el catálogo de contenido vive en
-- los archivos JSON del cliente Godot en apps/client_godot/resources/.
-- Usar seed.sql para poblar feature_entitlements en el esquema 20260331.

-- ============================================================
-- Plantillas
-- ============================================================
insert into public.template_definition (key, display_name, mood, estimated_duration_minutes, difficulty, scene_config)
values
  (
    'abandoned_house',
    'Casa abandonada',
    'claustrofóbico',
    5,
    'normal',
    '{"environment":"interior_dark","lighting_preset":"candle_flicker","audio_ambience":"ambient_abandoned_house","starting_room":"entrance_hall","rooms":["entrance_hall","living_room","kitchen","basement"],"fog_density":0.4,"default_atmosphere_preset":"oppressive"}'
  ),
  (
    'forest_night',
    'Bosque nocturno',
    'abierto y opresivo',
    7,
    'difícil',
    '{"environment":"exterior_forest","lighting_preset":"moonlight_sparse","audio_ambience":"ambient_forest_night","starting_room":"forest_edge","rooms":["forest_edge","clearing","ruins","old_well"],"fog_density":0.6,"default_atmosphere_preset":"primal_fear"}'
  ),
  (
    'hospital',
    'Hospital olvidado',
    'desolación y amenaza latente',
    8,
    'normal',
    '{"environment":"interior_large","lighting_preset":"fluorescent_broken","audio_ambience":"ambient_hospital","starting_room":"main_corridor","rooms":["main_corridor","ward","operating_room","morgue","rooftop"],"fog_density":0.2,"default_atmosphere_preset":"clinical_dread"}'
  );

-- ============================================================
-- Amenazas
-- ============================================================
insert into public.threat_definition (key, display_name, behavior_config)
values
  (
    'shadow_figure',
    'Figura en las sombras',
    '{"detection_radius":8.0,"chase_speed":3.5,"idle_speed":1.2,"visibility":"partial","aggression_curve":"escalating","special_ability":"flicker_lights_on_proximity","audio_cue_idle":"sfx_shadow_breathe","audio_cue_chase":"sfx_shadow_rush","patience_seconds":12,"can_open_doors":false}'
  ),
  (
    'presence',
    'La presencia',
    '{"detection_radius":6.0,"chase_speed":0.0,"idle_speed":0.0,"visibility":"none","aggression_curve":"constant_ambient","special_ability":"move_objects_and_drop_temperature","audio_cue_idle":"sfx_presence_hum","audio_cue_chase":"sfx_presence_surge","patience_seconds":-1,"can_open_doors":true}'
  ),
  (
    'crawler',
    'El arrastrado',
    '{"detection_radius":5.0,"chase_speed":6.0,"idle_speed":2.0,"visibility":"full","aggression_curve":"sudden_burst","special_ability":"hidden_until_triggered","audio_cue_idle":"sfx_crawler_scratch","audio_cue_chase":"sfx_crawler_sprint","patience_seconds":8,"can_open_doors":false}'
  );

-- ============================================================
-- Eventos
-- ============================================================
insert into public.event_definition (key, display_name, event_type, timing_rules, payload_schema)
values
  (
    'door_slam',
    'Puerta que se cierra',
    'environmental',
    '{"trigger":"proximity","min_interval_seconds":30,"can_repeat":true,"max_occurrences":3}',
    '{"room_id":{"type":"string","required":true},"intensity":{"type":"string","enum":["soft","loud"],"default":"loud"},"audio_cue":{"type":"string","default":"sfx_door_slam"}}'
  ),
  (
    'whisper',
    'Susurro',
    'audio',
    '{"trigger":"time_elapsed","min_interval_seconds":45,"can_repeat":true,"max_occurrences":5}',
    '{"line_key":{"type":"string","required":true},"spatialized":{"type":"boolean","default":true},"audio_cue":{"type":"string","default":"sfx_whisper_base"}}'
  ),
  (
    'light_flicker',
    'Parpadeo de luz',
    'environmental',
    '{"trigger":"threat_proximity","min_interval_seconds":15,"can_repeat":true,"max_occurrences":-1}',
    '{"room_id":{"type":"string","required":true},"duration_seconds":{"type":"number","default":2.5},"flicker_pattern":{"type":"string","enum":["random","rhythmic","single"],"default":"random"}}'
  ),
  (
    'footsteps',
    'Pasos',
    'audio',
    '{"trigger":"time_elapsed","min_interval_seconds":60,"can_repeat":true,"max_occurrences":4}',
    '{"direction":{"type":"string","enum":["above","below","side","behind"],"default":"behind"},"surface":{"type":"string","enum":["wood","concrete","gravel"],"default":"wood"},"audio_cue":{"type":"string","default":"sfx_footsteps_wood"}}'
  ),
  (
    'object_move',
    'Objeto que se mueve',
    'visual',
    '{"trigger":"room_enter","min_interval_seconds":90,"can_repeat":false,"max_occurrences":1}',
    '{"object_id":{"type":"string","required":true},"animation":{"type":"string","enum":["fall","slide","rotate"],"default":"fall"},"audio_cue":{"type":"string","default":"sfx_object_fall"}}'
  );

-- ============================================================
-- Finales
-- ============================================================
insert into public.ending_definition (key, display_name, resolution_type, conditions_schema, result_screen)
values
  (
    'escape',
    'Escapas',
    'success',
    '{"type":"objective_completed","objective_id":{"type":"string","required":true},"exit_trigger":{"type":"string","required":true}}',
    '{"title_key":"ending_escape_title","body_key":"ending_escape_body","show_survived_time":true,"cta_share":true,"cta_replay":true}'
  ),
  (
    'consumed',
    'Eres consumido',
    'failure',
    '{"type":"threat_contact","threat_id":{"type":"string","required":true},"grace_period_seconds":{"type":"number","default":0}}',
    '{"title_key":"ending_consumed_title","body_key":"ending_consumed_body","show_survived_time":true,"cta_share":true,"cta_replay":true}'
  );

-- ============================================================
-- Presets de atmósfera
-- ============================================================
insert into public.atmosphere_preset (key, display_name, visual_config, audio_config)
values
  (
    'oppressive',
    'Opresivo',
    '{"color_grade":"desaturated_warm","vignette_intensity":0.6,"grain_intensity":0.3,"blur_edges":true}',
    '{"reverb_preset":"small_room","low_pass_cutoff":800,"ambient_volume":0.8}'
  ),
  (
    'primal_fear',
    'Miedo primario',
    '{"color_grade":"cold_blue","vignette_intensity":0.4,"grain_intensity":0.5,"blur_edges":false}',
    '{"reverb_preset":"outdoor_night","low_pass_cutoff":1200,"ambient_volume":0.6}'
  ),
  (
    'clinical_dread',
    'Terror clínico',
    '{"color_grade":"cold_white","vignette_intensity":0.3,"grain_intensity":0.15,"blur_edges":false}',
    '{"reverb_preset":"large_corridor","low_pass_cutoff":2000,"ambient_volume":0.5}'
  );

-- ============================================================
-- Feature entitlements por plan
-- ============================================================
insert into public.feature_entitlement (plan_key, feature_key, is_enabled, limits_json)
values
  ('free',    'create_project',      true,  '{"max_projects":3}'),
  ('free',    'publish_project',     true,  '{"max_published":1}'),
  ('free',    'teaser_generation',   true,  '{"watermark":true}'),
  ('free',    'analytics_basic',     true,  '{}'),
  ('free',    'playtest',            true,  '{}'),
  ('premium', 'create_project',      true,  '{"max_projects":-1}'),
  ('premium', 'publish_project',     true,  '{"max_published":-1}'),
  ('premium', 'teaser_generation',   true,  '{"watermark":false}'),
  ('premium', 'analytics_basic',     true,  '{}'),
  ('premium', 'analytics_advanced',  true,  '{}'),
  ('premium', 'playtest',            true,  '{}'),
  ('premium', 'remix',               false, '{}');
