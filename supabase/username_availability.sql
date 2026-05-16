-- PULSO username availability support.
-- Run this in Supabase SQL Editor.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  email text,
  first_name text,
  middle_initial text,
  last_name text,
  suffix text,
  gender text check (
    gender in ('Female', 'Male', 'Non-binary', 'Prefer not to say')
  ),
  birthday date,
  full_name text,
  account_type text check (
    account_type in ('personal', 'business', 'organization')
  ) default 'personal',
  avatar_url text,
  updated_at timestamp with time zone default now()
);

alter table public.profiles
add column if not exists username text;

alter table public.profiles
add column if not exists email text;

alter table public.profiles
add column if not exists first_name text;

alter table public.profiles
add column if not exists middle_initial text;

alter table public.profiles
add column if not exists last_name text;

alter table public.profiles
add column if not exists suffix text;

alter table public.profiles
add column if not exists gender text;

alter table public.profiles
add column if not exists birthday date;

alter table public.profiles
add column if not exists full_name text;

alter table public.profiles
add column if not exists account_type text default 'personal';

update public.profiles as profile
set email = auth_user.email
from auth.users as auth_user
where profile.id = auth_user.id
  and profile.email is null;

create unique index if not exists profiles_username_lower_key
on public.profiles (lower(trim(username)))
where username is not null;

alter table public.profiles enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;

create policy "Users can view own profile"
on public.profiles
for select
using (auth.uid() = id);

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "Users can insert own profile"
on public.profiles
for insert
with check (auth.uid() = id);

create or replace function public.normalize_username(username text)
returns text
language sql
immutable
set search_path = public
as $$
  select lower(trim(username));
$$;

create or replace function public.is_username_available(requested_username text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1
    from public.profiles
    where public.normalize_username(username) =
      public.normalize_username(requested_username)
  );
$$;

grant execute on function public.normalize_username(text) to anon;
grant execute on function public.normalize_username(text) to authenticated;
grant execute on function public.is_username_available(text) to anon;
grant execute on function public.is_username_available(text) to authenticated;

create or replace function public.get_email_by_username(
  requested_username text
)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select email
  from public.profiles
  where public.normalize_username(username) =
    public.normalize_username(requested_username)
  limit 1;
$$;

grant execute on function public.get_email_by_username(text) to anon;
grant execute on function public.get_email_by_username(text) to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    username,
    email,
    first_name,
    middle_initial,
    last_name,
    suffix,
    gender,
    birthday,
    full_name,
    account_type,
    updated_at
  )
  values (
    new.id,
    public.normalize_username(new.raw_user_meta_data->>'username'),
    new.email,
    new.raw_user_meta_data->>'first_name',
    nullif(new.raw_user_meta_data->>'middle_initial', ''),
    new.raw_user_meta_data->>'last_name',
    nullif(new.raw_user_meta_data->>'suffix', ''),
    new.raw_user_meta_data->>'gender',
    (new.raw_user_meta_data->>'birthday')::date,
    new.raw_user_meta_data->>'full_name',
    coalesce(new.raw_user_meta_data->>'account_type', 'personal'),
    now()
  )
  on conflict (id) do update
  set
    username = excluded.username,
    email = excluded.email,
    first_name = excluded.first_name,
    middle_initial = excluded.middle_initial,
    last_name = excluded.last_name,
    suffix = excluded.suffix,
    gender = excluded.gender,
    birthday = excluded.birthday,
    full_name = excluded.full_name,
    account_type = excluded.account_type,
    updated_at = excluded.updated_at;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_user();

notify pgrst, 'reload schema';
