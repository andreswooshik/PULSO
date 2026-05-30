# PULSO

PULSO is a Flutter community social app built around authentication, profiles, posting, likes, comments, follows, and realtime updates. The app uses Supabase for authentication, database records, storage, row level security, and realtime subscriptions.

## Features

- Email and username login through Supabase Auth.
- Multi-step registration with profile metadata capture.
- Username normalization and availability checks.
- Profile viewing and editing.
- Profile avatar selection and update flow.
- Feed screen with post loading and realtime refresh.
- Post creation with optional image upload to Supabase Storage.
- Likes, comments, and follows backed by Supabase tables.
- Realtime comment, post, and like subscriptions.
- Row level security policies for user-owned data.

## Tech Stack

- Flutter and Dart
- Supabase Auth, Postgres, Storage, Realtime, and RPC functions
- Riverpod for state management
- GoRouter for app routing
- `flutter_dotenv` for local environment variables
- `image_picker`, `image_cropper`, `file_picker`, and `image` for media handling
- `flutter_test` and `mocktail` for tests

## Requirements

- Flutter SDK with Dart compatible with `sdk: ^3.10.3`
- A Supabase project
- Git
- A browser or device/emulator for running Flutter

## Getting Started

Clone the repository and install dependencies:

```powershell
git clone https://github.com/andreswooshik/PULSO.git
cd PULSO
flutter pub get
```

Create a local `.env` file in the project root:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Then run the app:

```powershell
flutter run -d chrome
```

You can also run on another available device:

```powershell
flutter devices
flutter run -d <device-id>
```

## Supabase Setup

1. Create or open a Supabase project.
2. Open the Supabase SQL Editor.
3. Run the full SQL script in `supabase/schema.sql`.
4. Confirm that the app's `.env` values match your Supabase project URL and anon key.
5. Fully restart the Flutter app after changing `.env` values.

The schema includes:

- `profiles`, `posts`, `likes`, `comments`, and `follows` tables.
- Row level security policies for authenticated user actions.
- Public profile/count views used by the feed and profile screens.
- Username helpers such as `normalize_username`, `is_username_available`, and `get_email_by_username`.
- A trigger that creates or updates a profile row after a Supabase Auth user is created.

## Environment and Security Notes

- Do not commit `.env` or any secret keys.
- `.env` is listed in `.gitignore`.
- Use only the Supabase anon key in the Flutter app.
- Never place a Supabase service role key in client-side code.
- Keep username validation on both the client and database side.
- Keep Row Level Security enabled for user-owned records.
- If username login fails while email login works, check that `get_email_by_username` exists in Supabase and accepts `requested_username`.

## Running Tests

Run all tests:

```powershell
flutter test
```

Run the focused authentication tests:

```powershell
flutter test test\features\auth\data\auth_service_test.dart test\features\auth\providers\auth_provider_test.dart
```

## Project Structure

```text
lib/
  core/
    constants/      Shared constants
    routing/        GoRouter routes and app shell
    theme/          App theme
    widgets/        Reusable shared widgets
  features/
    activity/       Activity screen
    auth/           Login, signup, auth state, and Supabase auth service
    comments/       Comment repository and comments sheet
    feed/           Feed screen and feed repository
    follows/        Follow repository
    likes/          Like repository, provider, and button
    posts/          Post creation screen
    profile/        Profile screen, avatar picker, profile state, and repository
supabase/
  schema.sql        Database schema, RLS policies, views, triggers, and RPCs
test/
  features/         Unit tests for feature data/providers
```

Additional architecture notes are available in `PROJECT_STRUCTURE.md` and `docs/foundation.md`.

## Useful Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Troubleshooting

### Supabase is not configured

Check that `.env` exists in the project root and uses this exact format:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

After editing `.env`, stop and rerun the Flutter app.

### Username login does not work

Email login uses Supabase Auth directly. Username login first resolves the username to an email through the `get_email_by_username` RPC. If username login fails:

- Run the latest `supabase/schema.sql` in Supabase.
- Confirm the RPC parameter is `requested_username`.
- Confirm the username exists in the `profiles` table.
- Restart the app after code or environment changes.

### Signup says username is taken

The app normalizes usernames by trimming spaces and lowercasing them. For example, `Juan_DelaCruz` and `juan_delacruz` are treated as the same username.

## Contributors

Thanks to everyone who contributed to PULSO.

- Ralf Andre Ebuna - [@andreswooshik](https://github.com/andreswooshik)
- Clarence Adal - [@clarenceadal](https://github.com/clarenceadal)
- Dan Ballares - [@forgetmenot34](https://github.com/forgetmenot34)
- Jan Lurence - [@aichrty](https://github.com/aichrty)

Contributor names were gathered from the repository's GitHub contributor list and local git history.
