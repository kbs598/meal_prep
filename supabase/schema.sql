-- Weeknight Five shared-family database
-- Run this entire file once in Supabase: SQL Editor > New query > paste > Run.

create extension if not exists pgcrypto;

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  created_at timestamptz not null default now(),
  primary key (family_id, user_id)
);

create table if not exists public.family_recipes (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  recipe_id text not null check (char_length(recipe_id) between 1 and 200),
  created_by uuid not null references auth.users(id) on delete cascade,
  recipe_name text not null check (char_length(recipe_name) between 1 and 300),
  meal_type text not null check (meal_type in ('Dinner', 'Breakfast', 'Lunch')),
  protein text not null check (protein in ('Chicken', 'Turkey', 'Beef', 'Pork', 'Fish', 'Meatless')),
  recipe_payload text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_id, recipe_id)
);

create table if not exists public.user_app_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state_payload text,
  deals_payload text,
  updated_at timestamptz not null default now()
);

alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_recipes enable row level security;
alter table public.user_app_data enable row level security;

revoke all on public.families from anon;
revoke all on public.family_members from anon;
revoke all on public.family_recipes from anon;
revoke all on public.user_app_data from anon;

grant select on public.families to authenticated;
grant select on public.family_members to authenticated;
grant select, insert, update, delete on public.family_recipes to authenticated;
grant select, insert, update, delete on public.user_app_data to authenticated;

drop policy if exists "Members can view their families" on public.families;
create policy "Members can view their families"
on public.families for select to authenticated
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = families.id and fm.user_id = auth.uid()
  )
);

drop policy if exists "Users can view their membership" on public.family_members;
create policy "Users can view their membership"
on public.family_members for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Members can view family recipes" on public.family_recipes;
create policy "Members can view family recipes"
on public.family_recipes for select to authenticated
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = family_recipes.family_id and fm.user_id = auth.uid()
  )
);

drop policy if exists "Members can add family recipes" on public.family_recipes;
create policy "Members can add family recipes"
on public.family_recipes for insert to authenticated
with check (
  created_by = auth.uid()
  and exists (
    select 1 from public.family_members fm
    where fm.family_id = family_recipes.family_id and fm.user_id = auth.uid()
  )
);

drop policy if exists "Creators and owners can update family recipes" on public.family_recipes;
drop policy if exists "Members can update family recipes" on public.family_recipes;
create policy "Members can update family recipes"
on public.family_recipes for update to authenticated
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = family_recipes.family_id
      and fm.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = family_recipes.family_id and fm.user_id = auth.uid()
  )
);

drop policy if exists "Creators and owners can delete family recipes" on public.family_recipes;
drop policy if exists "Members can delete family recipes" on public.family_recipes;
create policy "Members can delete family recipes"
on public.family_recipes for delete to authenticated
using (
  exists (
    select 1 from public.family_members fm
    where fm.family_id = family_recipes.family_id
      and fm.user_id = auth.uid()
  )
);

drop policy if exists "Users can view their planner data" on public.user_app_data;
create policy "Users can view their planner data"
on public.user_app_data for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can add their planner data" on public.user_app_data;
create policy "Users can add their planner data"
on public.user_app_data for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "Users can update their planner data" on public.user_app_data;
create policy "Users can update their planner data"
on public.user_app_data for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "Users can delete their planner data" on public.user_app_data;
create policy "Users can delete their planner data"
on public.user_app_data for delete to authenticated
using (user_id = auth.uid());

create index if not exists family_members_user_id_idx on public.family_members(user_id);
create unique index if not exists family_members_one_family_per_user_idx on public.family_members(user_id);
create index if not exists family_recipes_family_id_idx on public.family_recipes(family_id);

-- Deliberately no public policies and no browser permission to edit families or
-- memberships. Family administration happens in the trusted Supabase dashboard.
