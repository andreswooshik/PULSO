create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  email text,
  first_name text not null,
  middle_initial text,
  last_name text not null,
  suffix text,
  gender text not null check (
    gender in ('Female', 'Male', 'Non-binary', 'Prefer not to say')
  ),
  birthday date not null,
  full_name text,
  account_type text not null default 'personal' check (
    account_type in ('personal', 'business', 'organization')
  ),
  bio text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  image_url text,
  caption text,
  created_at timestamptz not null default now()
);

create table if not exists public.likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

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

alter table public.profiles
add column if not exists bio text;

alter table public.profiles
add column if not exists avatar_url text;

alter table public.comments
add column if not exists updated_at timestamptz not null default now();

create unique index if not exists profiles_username_lower_key
on public.profiles (lower(trim(username)))
where username is not null;

create index if not exists comments_post_id_created_at_idx
on public.comments (post_id, created_at asc);

create index if not exists comments_user_id_created_at_idx
on public.comments (user_id, created_at desc);

create index if not exists follows_follower_id_idx
on public.follows (follower_id);

create index if not exists follows_following_id_idx
on public.follows (following_id);

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.likes enable row level security;
alter table public.comments enable row level security;
alter table public.follows enable row level security;

drop policy if exists "profiles are readable by everyone" on public.profiles;
drop policy if exists "profiles are readable by user" on public.profiles;
create policy "profiles are readable by authenticated users"
on public.profiles for select
to authenticated
using (true);

create or replace view public.public_profiles as
select id, username, full_name, bio, avatar_url, created_at, updated_at
from public.profiles;

grant select on public.public_profiles to anon, authenticated;

drop policy if exists "users can insert their profile" on public.profiles;
create policy "users can insert their profile"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "users can update their profile" on public.profiles;
create policy "users can update their profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "posts are readable by everyone" on public.posts;
create policy "posts are readable by everyone"
on public.posts for select
using (true);

drop policy if exists "users can create posts" on public.posts;
create policy "users can create posts"
on public.posts for insert
with check (auth.uid() = user_id);

drop policy if exists "users can update their posts" on public.posts;
create policy "users can update their posts"
on public.posts for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can delete their posts" on public.posts;
create policy "users can delete their posts"
on public.posts for delete
using (auth.uid() = user_id);

drop policy if exists "likes are readable by everyone" on public.likes;
create policy "likes are readable by everyone"
on public.likes for select
using (true);

drop policy if exists "users can like as themselves" on public.likes;
create policy "users can like as themselves"
on public.likes for insert
with check (auth.uid() = user_id);

drop policy if exists "users can remove their likes" on public.likes;
create policy "users can remove their likes"
on public.likes for delete
using (auth.uid() = user_id);

drop policy if exists "comments are readable by everyone" on public.comments;
create policy "comments are readable by everyone"
on public.comments for select
using (true);

drop policy if exists "users can comment as themselves" on public.comments;
create policy "users can comment as themselves"
on public.comments for insert
with check (auth.uid() = user_id);

drop policy if exists "users can update their comments" on public.comments;
create policy "users can update their comments"
on public.comments for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users can delete their comments" on public.comments;
create policy "users can delete their comments"
on public.comments for delete
using (auth.uid() = user_id);

drop policy if exists "follows are readable by everyone" on public.follows;
create policy "follows are readable by everyone"
on public.follows for select
using (true);

drop policy if exists "users can follow as themselves" on public.follows;
create policy "users can follow as themselves"
on public.follows for insert
with check (auth.uid() = follower_id);

drop policy if exists "users can unfollow as themselves" on public.follows;
create policy "users can unfollow as themselves"
on public.follows for delete
using (auth.uid() = follower_id);

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

create or replace view public.post_comment_counts
with (security_invoker = true) as
select
  post_id,
  count(*)::int as comment_count
from public.comments
group by post_id;

create or replace view public.profile_follow_counts
with (security_invoker = true) as
select
  p.id as profile_id,
  coalesce(followers.count, 0)::int as followers_count,
  coalesce(following.count, 0)::int as following_count
from public.public_profiles p
left join (
  select following_id, count(*) as count
  from public.follows
  group by following_id
) followers on followers.following_id = p.id
left join (
  select follower_id, count(*) as count
  from public.follows
  group by follower_id
) following on following.follower_id = p.id;

create or replace view public.profile_post_counts
with (security_invoker = true) as
select
  user_id as profile_id,
  count(*)::int as posts_count
from public.posts
group by user_id;

grant select on public.post_comment_counts to anon, authenticated;
grant select on public.profile_follow_counts to anon, authenticated;
grant select on public.profile_post_counts to anon, authenticated;

notify pgrst, 'reload schema';
create or replace function get_email_by_username(p_username text)
returns text
language sql
security definer
as $body$
  select email from public.profiles where username = p_username limit 1;
$body$;
