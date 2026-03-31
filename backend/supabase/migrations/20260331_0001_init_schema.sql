create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  handle text unique,
  display_name text,
  avatar_url text,
  bio text,
  social_links jsonb not null default '{}'::jsonb,
  is_public boolean not null default false,
  plan text not null default 'free',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  subtitle text,
  template_id text not null,
  threat_id text,
  atmosphere_preset_id text,
  story_payload jsonb not null default '{}'::jsonb,
  event_payload jsonb not null default '[]'::jsonb,
  ending_payload jsonb not null default '{}'::jsonb,
  visibility text not null default 'private' check (visibility in ('private', 'unlisted', 'public')),
  publish_slug text,
  status text not null default 'draft' check (status in ('draft', 'ready_to_publish', 'published', 'archived')),
  allow_remix boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  published_at timestamptz
);

create unique index if not exists idx_projects_publish_slug_unique
  on public.projects (publish_slug)
  where publish_slug is not null;

create index if not exists idx_projects_owner_id on public.projects(owner_id);
create index if not exists idx_projects_status on public.projects(status);
create index if not exists idx_projects_published_at on public.projects(published_at);

create table if not exists public.play_sessions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  player_id uuid references auth.users(id) on delete set null,
  started_at timestamptz not null default timezone('utc', now()),
  completed_at timestamptz,
  outcome text,
  ending_id text,
  survived_seconds integer,
  shared_result boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_play_sessions_project_id on public.play_sessions(project_id);
create index if not exists idx_play_sessions_started_at on public.play_sessions(started_at);

create table if not exists public.generated_assets (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  asset_type text not null check (asset_type in ('teaser', 'thumbnail_square', 'thumbnail_vertical', 'other')),
  storage_path text not null,
  generation_status text not null default 'pending' check (generation_status in ('pending', 'ready', 'failed')),
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_generated_assets_project_id on public.generated_assets(project_id);

create table if not exists public.analytics_events (
  id bigint generated always as identity primary key,
  project_id uuid references public.projects(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  session_id uuid references public.play_sessions(id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_analytics_events_project_id on public.analytics_events(project_id);
create index if not exists idx_analytics_events_event_name on public.analytics_events(event_name);
create index if not exists idx_analytics_events_created_at on public.analytics_events(created_at);

create table if not exists public.feature_entitlements (
  id uuid primary key default gen_random_uuid(),
  plan_key text not null,
  feature_key text not null,
  is_enabled boolean not null default true,
  limits_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  unique(plan_key, feature_key)
);

create or replace function public.generate_project_slug(input_title text, fallback_id uuid)
returns text
language plpgsql
as $$
declare
  base_slug text;
  candidate text;
  suffix integer := 0;
begin
  base_slug := lower(trim(coalesce(input_title, 'project')));
  base_slug := regexp_replace(base_slug, '[^a-z0-9]+', '-', 'g');
  base_slug := regexp_replace(base_slug, '(^-|-$)', '', 'g');
  base_slug := nullif(base_slug, '');

  if base_slug is null then
    base_slug := 'project-' || left(replace(fallback_id::text, '-', ''), 8);
  end if;

  candidate := base_slug;

  while exists (
    select 1
    from public.projects
    where publish_slug = candidate
      and id <> fallback_id
  ) loop
    suffix := suffix + 1;
    candidate := base_slug || '-' || suffix::text;
  end loop;

  return candidate;
end;
$$;

create or replace function public.publish_project(p_project_id uuid)
returns public.projects
language plpgsql
security definer
set search_path = public
as $$
declare
  target_project public.projects;
begin
  select *
  into target_project
  from public.projects
  where id = p_project_id
    and owner_id = auth.uid();

  if target_project.id is null then
    raise exception 'project_not_found_or_forbidden';
  end if;

  if coalesce(trim(target_project.title), '') = '' then
    raise exception 'project_title_required';
  end if;

  if coalesce(trim(target_project.template_id), '') = '' then
    raise exception 'project_template_required';
  end if;

  update public.projects
  set
    publish_slug = coalesce(target_project.publish_slug, public.generate_project_slug(target_project.title, target_project.id)),
    status = 'published',
    visibility = case when target_project.visibility = 'private' then 'unlisted' else target_project.visibility end,
    published_at = coalesce(target_project.published_at, timezone('utc', now())),
    updated_at = timezone('utc', now())
  where id = p_project_id
  returning * into target_project;

  return target_project;
end;
$$;

create or replace function public.log_analytics_event(
  p_event_name text,
  p_project_id uuid default null,
  p_session_id uuid default null,
  p_properties jsonb default '{}'::jsonb
)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  inserted_id bigint;
begin
  insert into public.analytics_events (
    project_id,
    user_id,
    session_id,
    event_name,
    properties
  ) values (
    p_project_id,
    auth.uid(),
    p_session_id,
    p_event_name,
    coalesce(p_properties, '{}'::jsonb)
  )
  returning id into inserted_id;

  return inserted_id;
end;
$$;

create trigger trg_profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger trg_projects_set_updated_at
before update on public.projects
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.play_sessions enable row level security;
alter table public.generated_assets enable row level security;
alter table public.analytics_events enable row level security;
alter table public.feature_entitlements enable row level security;

create policy "profiles_select_public_or_owner"
on public.profiles
for select
using (is_public = true or auth.uid() = user_id);

create policy "profiles_insert_self"
on public.profiles
for insert
with check (auth.uid() = user_id);

create policy "profiles_update_self"
on public.profiles
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "projects_owner_full_access"
on public.projects
for all
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

create policy "projects_select_published"
on public.projects
for select
using (status = 'published' and publish_slug is not null);

create policy "play_sessions_insert_for_published_projects"
on public.play_sessions
for insert
with check (
  exists (
    select 1
    from public.projects p
    where p.id = project_id
      and p.status = 'published'
      and p.publish_slug is not null
  )
);

create policy "play_sessions_select_owner"
on public.play_sessions
for select
using (
  exists (
    select 1
    from public.projects p
    where p.id = project_id
      and p.owner_id = auth.uid()
  )
);

create policy "generated_assets_select_owner"
on public.generated_assets
for select
using (
  exists (
    select 1
    from public.projects p
    where p.id = project_id
      and p.owner_id = auth.uid()
  )
);

create policy "generated_assets_insert_owner"
on public.generated_assets
for insert
with check (
  exists (
    select 1
    from public.projects p
    where p.id = project_id
      and p.owner_id = auth.uid()
  )
);

create policy "analytics_events_insert_any_authenticated_or_anon"
on public.analytics_events
for insert
with check (true);

create policy "analytics_events_select_owner"
on public.analytics_events
for select
using (
  project_id is not null
  and exists (
    select 1
    from public.projects p
    where p.id = project_id
      and p.owner_id = auth.uid()
  )
);

create policy "feature_entitlements_select_all"
on public.feature_entitlements
for select
using (true);
