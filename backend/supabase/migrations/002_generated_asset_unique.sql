-- Migration: 002_generated_asset_unique_constraint
-- Descripción: añade restricción única en (project_id, asset_type) para soportar
-- el upsert de la Edge Function generate_asset sin duplicados.

alter table public.generated_asset
  add constraint generated_asset_project_type_unique unique (project_id, asset_type);
