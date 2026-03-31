-- Migration: 001_initial_schema
-- Descripción: esquema inicial para usuarios, proyectos, sesiones, assets y feature flags

-- ============================================================
-- Extensiones
-- ============================================================
create extension if not exists "uuid-ossp";

-- ============================================================
-- Enumeraciones
-- ============================================================
create type project_status as enum ('draft', 'ready_to_publish', 'published', 'archived');
create type plan_key as enum ('free', 'premium');
create type asset_type as enum ('thumbnail', 'teaser_video', 'cover');
create type generation_status as enum ('pending', 'processing', 'ready', 'failed');
create type play_outcome as enum ('completed', 'abandoned', 'failed');

-- ============================================================
-- Perfil de usuario (extiende auth.users de Supabase)
-- ============================================================
create table public.user_profile (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  handle       text unique not null,
  display_name text not null,
  avatar_url   text,
  bio          text,
  social_links jsonb default '{}',
  is_public    boolean not null default true,
  plan         plan_key not null default 'free',
  created_at   timestamptz not null default now()
);

alter table public.user_profile enable row level security;

create policy "owner can read own profile"
  on public.user_profile for select
  using (auth.uid() = user_id);

create policy "owner can update own profile"
  on public.user_profile for update
  using (auth.uid() = user_id);

create policy "public profiles are visible"
  on public.user_profile for select
  using (is_public = true);

-- ============================================================
-- Catálogo de plantillas (datos gestionados por el equipo)
-- ============================================================
create table public.template_definition (
  id                          uuid primary key default uuid_generate_v4(),
  key                         text unique not null,
  display_name                text not null,
  mood                        text not null,
  estimated_duration_minutes  integer not null,
  difficulty                  text not null,
  scene_config                jsonb not null default '{}',
  is_active                   boolean not null default true,
  created_at                  timestamptz not null default now()
);

alter table public.template_definition enable row level security;

create policy "templates are readable by all"
  on public.template_definition for select
  using (is_active = true);

-- ============================================================
-- Catálogo de amenazas
-- ============================================================
create table public.threat_definition (
  id              uuid primary key default uuid_generate_v4(),
  key             text unique not null,
  display_name    text not null,
  behavior_config jsonb not null default '{}',
  is_active       boolean not null default true,
  created_at      timestamptz not null default now()
);

alter table public.threat_definition enable row level security;

create policy "threats are readable by all"
  on public.threat_definition for select
  using (is_active = true);

-- ============================================================
-- Catálogo de eventos
-- ============================================================
create table public.event_definition (
  id             uuid primary key default uuid_generate_v4(),
  key            text unique not null,
  display_name   text not null,
  event_type     text not null,
  timing_rules   jsonb not null default '{}',
  payload_schema jsonb not null default '{}',
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

alter table public.event_definition enable row level security;

create policy "events are readable by all"
  on public.event_definition for select
  using (is_active = true);

-- ============================================================
-- Catálogo de finales
-- ============================================================
create table public.ending_definition (
  id                uuid primary key default uuid_generate_v4(),
  key               text unique not null,
  display_name      text not null,
  resolution_type   text not null,
  conditions_schema jsonb not null default '{}',
  result_screen     jsonb not null default '{}',
  is_active         boolean not null default true,
  created_at        timestamptz not null default now()
);

alter table public.ending_definition enable row level security;

create policy "endings are readable by all"
  on public.ending_definition for select
  using (is_active = true);

-- ============================================================
-- Presets de atmósfera
-- ============================================================
create table public.atmosphere_preset (
  id             uuid primary key default uuid_generate_v4(),
  key            text unique not null,
  display_name   text not null,
  visual_config  jsonb not null default '{}',
  audio_config   jsonb not null default '{}',
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

alter table public.atmosphere_preset enable row level security;

create policy "atmosphere presets are readable by all"
  on public.atmosphere_preset for select
  using (is_active = true);

-- ============================================================
-- Proyectos de usuario
-- ============================================================
create table public.project (
  id                    uuid primary key default uuid_generate_v4(),
  owner_id              uuid not null references auth.users(id) on delete cascade,
  title                 text not null,
  subtitle              text,
  template_id           uuid references public.template_definition(id),
  threat_id             uuid references public.threat_definition(id),
  atmosphere_preset_id  uuid references public.atmosphere_preset(id),
  story_payload         jsonb not null default '{}',
  event_payload         jsonb not null default '[]',
  ending_payload        jsonb not null default '{}',
  visibility            text not null default 'private',
  publish_slug          text unique,
  status                project_status not null default 'draft',
  allow_remix           boolean not null default false,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  published_at          timestamptz
);

create index project_owner_idx on public.project(owner_id);
create index project_slug_idx on public.project(publish_slug) where publish_slug is not null;
create index project_status_idx on public.project(status);

alter table public.project enable row level security;

create policy "owner can manage own projects"
  on public.project for all
  using (auth.uid() = owner_id);

create policy "published projects are readable by all"
  on public.project for select
  using (status = 'published' and visibility = 'public');

-- Actualiza updated_at automáticamente
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger project_updated_at
  before update on public.project
  for each row execute procedure public.set_updated_at();

-- ============================================================
-- Sesiones de juego
-- ============================================================
create table public.play_session (
  id               uuid primary key default uuid_generate_v4(),
  project_id       uuid not null references public.project(id) on delete cascade,
  player_id        uuid references auth.users(id) on delete set null,
  started_at       timestamptz not null default now(),
  completed_at     timestamptz,
  outcome          play_outcome,
  ending_id        uuid references public.ending_definition(id),
  survived_seconds integer,
  shared_result    boolean not null default false
);

create index play_session_project_idx on public.play_session(project_id);
create index play_session_player_idx on public.play_session(player_id) where player_id is not null;

alter table public.play_session enable row level security;

create policy "project owner can read sessions"
  on public.play_session for select
  using (
    exists (
      select 1 from public.project p
      where p.id = project_id and p.owner_id = auth.uid()
    )
  );

create policy "player can insert own session"
  on public.play_session for insert
  with check (auth.uid() = player_id or player_id is null);

create policy "player can update own session"
  on public.play_session for update
  using (auth.uid() = player_id);

-- ============================================================
-- Assets generados (teasers, miniaturas)
-- ============================================================
create table public.generated_asset (
  id                uuid primary key default uuid_generate_v4(),
  project_id        uuid not null references public.project(id) on delete cascade,
  asset_type        asset_type not null,
  storage_path      text,
  generation_status generation_status not null default 'pending',
  created_at        timestamptz not null default now()
);

create index generated_asset_project_idx on public.generated_asset(project_id);

alter table public.generated_asset enable row level security;

create policy "owner can read own assets"
  on public.generated_asset for select
  using (
    exists (
      select 1 from public.project p
      where p.id = project_id and p.owner_id = auth.uid()
    )
  );

-- ============================================================
-- Feature entitlements por plan
-- ============================================================
create table public.feature_entitlement (
  id          uuid primary key default uuid_generate_v4(),
  plan_key    plan_key not null,
  feature_key text not null,
  is_enabled  boolean not null default true,
  limits_json jsonb default '{}',
  unique (plan_key, feature_key)
);

alter table public.feature_entitlement enable row level security;

create policy "entitlements are readable by all"
  on public.feature_entitlement for select
  using (true);

-- ============================================================
-- Tabla de eventos analíticos
-- ============================================================
create table public.analytics_event (
  id         uuid primary key default uuid_generate_v4(),
  event_name text not null,
  user_id    uuid references auth.users(id) on delete set null,
  project_id uuid references public.project(id) on delete set null,
  session_id uuid references public.play_session(id) on delete set null,
  properties jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index analytics_event_name_idx on public.analytics_event(event_name);
create index analytics_event_project_idx on public.analytics_event(project_id) where project_id is not null;
create index analytics_event_created_idx on public.analytics_event(created_at);

alter table public.analytics_event enable row level security;

create policy "only service role can insert events"
  on public.analytics_event for insert
  with check (auth.role() = 'service_role');

create policy "project owner can read own project events"
  on public.analytics_event for select
  using (
    project_id is null or
    exists (
      select 1 from public.project p
      where p.id = project_id and p.owner_id = auth.uid()
    )
  );
