-- Extensions
create extension if not exists "pgcrypto";

-- User roles for app permissions
create table if not exists public.video_user_profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'viewer' check (role in ('viewer', 'technical_lead', 'cmm_specialist')),
  created_at timestamptz not null default now()
);

-- Categories
create table if not exists public.video_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);

-- Videos (separate table for all video data)
create table if not exists public.video_items (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  thumbnail_url text,
  video_url text not null,
  category_id uuid not null references public.video_categories (id) on delete restrict,
  likes integer not null default 0,
  views integer not null default 0,
  created_by uuid references auth.users (id),
  created_at timestamptz not null default now()
);

-- Reactions (separate table)
create table if not exists public.video_reactions (
  id uuid primary key default gen_random_uuid(),
  video_id uuid not null references public.video_items (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  reaction_type text not null check (reaction_type in ('like')),
  created_at timestamptz not null default now(),
  unique (video_id, user_id, reaction_type)
);

-- Helper function: role check
create or replace function public.current_video_role()
returns text
language sql
stable
as $$
  select coalesce(
    (select role from public.video_user_profiles where user_id = auth.uid()),
    'viewer'
  );
$$;

create or replace function public.increment_video_views(video_id_input uuid)
returns void
language sql
security definer
as $$
  update public.video_items
  set views = views + 1
  where id = video_id_input;
$$;

create or replace function public.increment_video_likes(video_id_input uuid)
returns void
language sql
security definer
as $$
  update public.video_items
  set likes = likes + 1
  where id = video_id_input;
$$;

create or replace function public.decrement_video_likes(video_id_input uuid)
returns void
language sql
security definer
as $$
  update public.video_items
  set likes = greatest(likes - 1, 0)
  where id = video_id_input;
$$;

-- RLS
alter table public.video_user_profiles enable row level security;
alter table public.video_categories enable row level security;
alter table public.video_items enable row level security;
alter table public.video_reactions enable row level security;

-- Profiles policies
create policy if not exists "profiles_select_own"
on public.video_user_profiles
for select
using (user_id = auth.uid());

create policy if not exists "profiles_insert_own"
on public.video_user_profiles
for insert
with check (user_id = auth.uid());

create policy if not exists "profiles_update_own"
on public.video_user_profiles
for update
using (user_id = auth.uid());

-- Categories policies
create policy if not exists "categories_read_all"
on public.video_categories
for select
using (true);

create policy if not exists "categories_manage_by_role"
on public.video_categories
for all
using (public.current_video_role() in ('technical_lead', 'cmm_specialist'))
with check (public.current_video_role() in ('technical_lead', 'cmm_specialist'));

-- Video policies
create policy if not exists "videos_read_all"
on public.video_items
for select
using (true);

create policy if not exists "videos_manage_by_role"
on public.video_items
for all
using (public.current_video_role() in ('technical_lead', 'cmm_specialist'))
with check (public.current_video_role() in ('technical_lead', 'cmm_specialist'));

-- Reactions policies
create policy if not exists "reactions_read_all"
on public.video_reactions
for select
using (true);

create policy if not exists "reactions_insert_own"
on public.video_reactions
for insert
with check (user_id = auth.uid());

create policy if not exists "reactions_delete_own"
on public.video_reactions
for delete
using (user_id = auth.uid());

grant execute on function public.increment_video_views(uuid) to authenticated;
grant execute on function public.increment_video_likes(uuid) to authenticated;
grant execute on function public.decrement_video_likes(uuid) to authenticated;
