insert into public.feature_entitlements (plan_key, feature_key, is_enabled, limits_json)
values
  ('free', 'publish_project', true, '{}'::jsonb),
  ('free', 'teaser_watermark', true, '{}'::jsonb),
  ('free', 'max_projects', true, '{"value": 3}'::jsonb),
  ('premium', 'publish_project', true, '{}'::jsonb),
  ('premium', 'teaser_watermark', false, '{}'::jsonb),
  ('premium', 'max_projects', true, '{"value": 100}'::jsonb)
on conflict (plan_key, feature_key)
do update set
  is_enabled = excluded.is_enabled,
  limits_json = excluded.limits_json;
