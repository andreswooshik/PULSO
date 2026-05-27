# Member D Scope Summary

This repo now covers the main Member D foundation pieces:

- `comments` table with insert, update, delete, and read policies
- `follows` table with follow and unfollow policies
- `post_comment_counts` view for thread counters
- `profile_follow_counts` view for follower/following counters

App-side coverage:

- Feed opens a real comments sheet per post
- Comments can be added and deleted by the comment owner
- Comments refresh through Supabase realtime changes
- Profile shows follower/following counts
- Profile includes follow and unfollow buttons for discoverable members

Remaining operational note:

- The local `supabase/schema.sql` file must still be run in Supabase SQL Editor
  for remote database changes to take effect.
