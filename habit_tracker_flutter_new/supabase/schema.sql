-- Supabase schema for habit-tracker-flutter
-- Idempotent: safe to re-run. Run in Supabase SQL Editor or via: supabase db push

-- ============ ENUMS ============
do $$ begin
  create type habit_frequency as enum ('everyDay', 'weekdays', 'weekends', 'custom');
exception when duplicate_object then null; end $$;

do $$ begin
  create type habit_category as enum (
    'health', 'productivity', 'fitness', 'mindfulness',
    'learning', 'social', 'creativity', 'finance', 'other'
  );
exception when duplicate_object then null; end $$;

-- ============ USER PROFILES ============
-- Registration/login itself is handled by Supabase Auth (auth.users).
-- This table stores app-facing profile data, auto-created on signup.
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  email        text not null,
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Auto-create a profile row whenever a user registers
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============ TABLES ============
create table if not exists public.habits (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name             text not null check (length(trim(name)) > 0),
  description      text,
  icon             text,
  frequency        habit_frequency not null default 'everyDay',
  custom_days      smallint[] check (
                     custom_days is null or custom_days <@ array[1,2,3,4,5,6,7]::smallint[]
                   ),
  category         habit_category not null default 'other',
  target_days      integer not null default 30 check (target_days > 0),
  has_grace_period boolean not null default false,
  is_archived      boolean not null default false,
  notes            text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),

  -- custom frequency requires custom_days
  constraint custom_days_required check (
    frequency <> 'custom' or (custom_days is not null and array_length(custom_days, 1) > 0)
  )
);

create table if not exists public.completions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users (id) on delete cascade,
  habit_id     uuid not null references public.habits (id) on delete cascade,
  completed_on date not null default current_date,
  created_at   timestamptz not null default now(),

  -- one completion per habit per day
  constraint completions_unique_per_day unique (habit_id, completed_on)
);

-- ============ INDEXES ============
create index if not exists habits_user_idx       on public.habits (user_id) where not is_archived;
create index if not exists completions_user_idx  on public.completions (user_id, completed_on desc);
create index if not exists completions_habit_idx on public.completions (habit_id, completed_on desc);

-- ============ updated_at TRIGGER ============
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists habits_set_updated_at on public.habits;
create trigger habits_set_updated_at
  before update on public.habits
  for each row execute function public.set_updated_at();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ============ ROW LEVEL SECURITY ============
alter table public.profiles    enable row level security;
alter table public.habits      enable row level security;
alter table public.completions enable row level security;

drop policy if exists "own profile select" on public.profiles;
create policy "own profile select" on public.profiles
  for select using (auth.uid() = id);
drop policy if exists "own profile update" on public.profiles;
create policy "own profile update" on public.profiles
  for update using (auth.uid() = id);

drop policy if exists "own habits select" on public.habits;
create policy "own habits select" on public.habits
  for select using (auth.uid() = user_id);
drop policy if exists "own habits insert" on public.habits;
create policy "own habits insert" on public.habits
  for insert with check (auth.uid() = user_id);
drop policy if exists "own habits update" on public.habits;
create policy "own habits update" on public.habits
  for update using (auth.uid() = user_id);
drop policy if exists "own habits delete" on public.habits;
create policy "own habits delete" on public.habits
  for delete using (auth.uid() = user_id);

drop policy if exists "own completions select" on public.completions;
create policy "own completions select" on public.completions
  for select using (auth.uid() = user_id);
drop policy if exists "own completions insert" on public.completions;
create policy "own completions insert" on public.completions
  for insert with check (
    auth.uid() = user_id
    and exists (select 1 from public.habits h where h.id = habit_id and h.user_id = auth.uid())
  );
drop policy if exists "own completions delete" on public.completions;
create policy "own completions delete" on public.completions
  for delete using (auth.uid() = user_id);

-- ============ HELPER VIEW: completion counts ============
create or replace view public.habit_completion_counts
with (security_invoker = on) as
select
  h.id as habit_id,
  h.user_id,
  count(c.id)          as total_completions,
  max(c.completed_on)  as last_completed_on
from public.habits h
left join public.completions c on c.habit_id = h.id
group by h.id, h.user_id;
