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
  created_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

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

create policy "comments are readable by everyone"
on public.comments for select
using (true);

create policy "users can comment as themselves"
on public.comments for insert
with check (auth.uid() = user_id);

create policy "users can delete their comments"
on public.comments for delete
using (auth.uid() = user_id);

create policy "follows are readable by everyone"
on public.follows for select
using (true);

create policy "users can follow as themselves"
on public.follows for insert
with check (auth.uid() = follower_id);

create policy "users can unfollow as themselves"
on public.follows for delete
using (auth.uid() = follower_id);
