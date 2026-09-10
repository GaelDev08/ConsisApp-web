-- ============================================================
--  ConsisApp - Esquema Supabase
--  Pega esto en: Supabase Dashboard -> SQL Editor -> New query
-- ============================================================

create extension if not exists pgcrypto;

-- PROFILES
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null default '',
  birthdate date,
  country text,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- APP SETTINGS
create table if not exists public.app_settings (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  active_goal_id text,
  weigh_in_weekday int not null default 1,
  theme_mode text not null default 'system',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- GOALS (metas)
create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null,              -- timeAccumulated|fitness|fasting|custom
  title text not null,
  frequency text not null,         -- daily|weekly
  unit text not null,              -- minutes|pages|hours|sessions
  target_value int not null default 0,
  context_tags jsonb not null default '[]',
  fasting jsonb,
  requires_nutrition boolean not null default true,
  requires_weight boolean not null default true,
  archived boolean not null default false,
  sort_order int not null default 0,
  scheduled_time text,
  created_at timestamptz not null default now()
);

-- SESSIONS
create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  goal_id uuid,
  day date not null,
  duration_minutes int not null default 0,
  quantity numeric,
  activities jsonb not null default '[]',
  tags jsonb not null default '[]',
  fasting_start_at timestamptz,
  fasting_end_at timestamptz,
  note text,
  created_at timestamptz not null default now()
);

-- WEIGHTS
create table if not exists public.weights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  date date not null,
  weight_kg numeric not null,
  source text not null default 'manual',
  created_at timestamptz not null default now()
);

-- NUTRITION CHECKS
create table if not exists public.nutrition_checks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  level int not null,           -- 0=green 1=yellow 2=red
  note text,
  created_at timestamptz not null default now()
);

-- FRICTIONS
create table if not exists public.frictions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  goal_id uuid,
  day date not null,
  tag text,
  custom_label text,
  note text,
  created_at timestamptz not null default now()
);

-- ============================================================
--  TRIGGER: crea el perfil automáticamente al registrarse
--  (así el email/profila aparece en public.profiles)
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
--  RLS: cada usuario solo ve/edita SUS propias filas
-- ============================================================
alter table public.profiles enable row level security;
alter table public.app_settings enable row level security;
alter table public.goals enable row level security;
alter table public.sessions enable row level security;
alter table public.weights enable row level security;
alter table public.nutrition_checks enable row level security;
alter table public.frictions enable row level security;

-- PROFILES
drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select using (auth.uid() = id);
drop policy if exists "profiles_upsert" on public.profiles;
create policy "profiles_upsert" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update" on public.profiles
  for update using (auth.uid() = id);

-- APP SETTINGS
drop policy if exists "app_settings_select" on public.app_settings;
create policy "app_settings_select" on public.app_settings
  for select using (auth.uid() = user_id);
create policy "app_settings_insert" on public.app_settings
  for insert with check (auth.uid() = user_id);
create policy "app_settings_update" on public.app_settings
  for update using (auth.uid() = user_id);
create policy "app_settings_delete" on public.app_settings
  for delete using (auth.uid() = user_id);

-- GOALS
drop policy if exists "goals_select" on public.goals;
create policy "goals_select" on public.goals
  for select using (auth.uid() = user_id);
create policy "goals_insert" on public.goals
  for insert with check (auth.uid() = user_id);
create policy "goals_update" on public.goals
  for update using (auth.uid() = user_id);
create policy "goals_delete" on public.goals
  for delete using (auth.uid() = user_id);

-- SESSIONS
drop policy if exists "sessions_select" on public.sessions;
create policy "sessions_select" on public.sessions
  for select using (auth.uid() = user_id);
create policy "sessions_insert" on public.sessions
  for insert with check (auth.uid() = user_id);
create policy "sessions_update" on public.sessions
  for update using (auth.uid() = user_id);
create policy "sessions_delete" on public.sessions
  for delete using (auth.uid() = user_id);

-- WEIGHTS
drop policy if exists "weights_select" on public.weights;
create policy "weights_select" on public.weights
  for select using (auth.uid() = user_id);
create policy "weights_insert" on public.weights
  for insert with check (auth.uid() = user_id);
create policy "weights_update" on public.weights
  for update using (auth.uid() = user_id);
create policy "weights_delete" on public.weights
  for delete using (auth.uid() = user_id);

-- NUTRITION CHECK
drop policy if exists "nutrition_select" on public.nutrition_checks;
create policy "nutrition_select" on public.nutrition_checks
  for select using (auth.uid() = user_id);
create policy "nutrition_insert" on public.nutrition_checks
  for insert with check (auth.uid() = user_id);
create policy "nutrition_update" on public.nutrition_checks
  for update using (auth.uid() = user_id);
create policy "nutrition_delete" on public.nutrition_checks
  for delete using (auth.uid() = user_id);

-- FRICTIONS
drop policy if exists "frictions_select" on public.frictions;
create policy "frictions_select" on public.frictions
  for select using (auth.uid() = user_id);
create policy "frictions_insert" on public.frictions
  for insert with check (auth.uid() = user_id);
create policy "frictions_update" on public.frictions
  for update using (auth.uid() = user_id);
create policy "frictions_delete" on public.frictions
  for delete using (auth.uid() = user_id);