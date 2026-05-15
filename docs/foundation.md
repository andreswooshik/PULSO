# Pulso Foundation

This branch sets up the shared foundation for all members.

## App Structure

- `lib/core/routing/` contains route names, GoRouter setup, and the bottom navigation shell.
- `lib/features/feed/` is the starting point for the post feed and post card integration.
- `lib/features/posts/` is the starting point for post creation and image upload.
- `lib/features/activity/` is the starting point for likes, comments, follows, and realtime activity.
- `lib/features/comments/data/`, `lib/features/follows/data/`, and `lib/features/likes/data/` contain starter Supabase repositories.
- `supabase/schema.sql` contains the baseline database tables and RLS policies.

## Member Starting Points

- Member A: connect authentication screens, session redirects, profile editing, and avatar upload.
- Member B: build `CreatePostScreen`, post upload/storage, and feed queries.
- Member C: build like state, live like counts, and realtime subscriptions.
- Member D: build comments, follow state, follower/following counts, and RLS audit notes.

## Before Feature Work

1. Create `.env` from `.env.example`.
2. Add Supabase URL and anon key.
3. Run `supabase/schema.sql` in the Supabase SQL editor.
4. Run `flutter test`.
