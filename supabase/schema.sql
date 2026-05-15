create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  display_name text,
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

alter table public.comments
add column if not exists updated_at timestamptz not null default now();

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

create policy "profiles are readable by everyone"
on public.profiles for select
using (true);

create policy "users can insert their profile"
on public.profiles for insert
with check (auth.uid() = id);

create policy "users can update their profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "posts are readable by everyone"
on public.posts for select
using (true);

create policy "users can create posts"
on public.posts for insert
with check (auth.uid() = user_id);

create policy "users can update their posts"
on public.posts for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can delete their posts"
on public.posts for delete
using (auth.uid() = user_id);

create policy "likes are readable by everyone"
on public.likes for select
using (true);

create policy "users can like as themselves"
on public.likes for insert
with check (auth.uid() = user_id);

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
from public.profiles p
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

grant select on public.post_comment_counts to anon, authenticated;
grant select on public.profile_follow_counts to anon, authenticated;

select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  p.policyname,
  p.cmd as policy_command
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policies p
  on p.schemaname = n.nspname
  and p.tablename = c.relname
where n.nspname = 'public'
  and c.relname in ('comments', 'follows')
order by c.relname, p.policyname;
