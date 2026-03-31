-- Migration: 002_generated_asset_unique_constraint
-- Descripción: añade restricción única en (project_id, asset_type) para soportar
-- el upsert de la Edge Function generate_asset sin duplicados.
-- Nota: aplica sobre la tabla canonical `generated_assets` definida en 20260331_0001_init_schema.sql

alter table public.generated_assets
  add constraint generated_assets_project_type_unique unique (project_id, asset_type);
