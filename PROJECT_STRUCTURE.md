# PULSO Project Structure

## Architecture Overview

PULSO follows **Clean Architecture** with **Feature-Based Organization**.

```
lib/
├── core/                          # Shared/Global code
│   ├── widgets/                   # Global reusable widgets
│   │   ├── custom_button.dart     # Used everywhere
│   │   ├── app_text_field.dart    # Used everywhere
│   │   └── widgets.dart           # Barrel export
│   ├── theme/
│   │   └── app_theme.dart         # Light & Dark themes
│   └── constants/
│       └── app_constants.dart     # App-wide constants
│
├── features/                       # Feature modules
│   ├── auth/                       # Authentication feature
│   │   ├── presentation/
│   │   │   ├── screens/           # Full screens
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── signup_screen.dart
│   │   │   └── widgets/           # Auth-only widgets
│   │   │       ├── social_login_button.dart
│   │   │       ├── password_validation_hint.dart
│   │   │       └── auth_widgets.dart  # Barrel export
│   │   ├── providers/             # Riverpod providers
│   │   ├── data/                  # API & local data
│   │   └── domain/                # Business logic
│   │
│   └── profile/                    # Profile feature
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── profile_screen.dart
│       │   └── widgets/
│       │       ├── avatar_picker.dart
│       │       ├── profile_stat_item.dart
│       │       └── profile_widgets.dart  # Barrel export
│       ├── providers/
│       ├── data/
│       └── domain/
│
└── main.dart                      # App entry point with Supabase & Riverpod init
```

## Key Principles

### 1. Global Components (lib/core/widgets/)
**Usage:** Reusable across the entire app
- `CustomButton` - Generic button with loading states
- `AppTextField` - Styled text input field
- Location: `lib/core/widgets/`
- Import: `import 'package:pulso/core/widgets/widgets.dart';`

### 2. Feature-Specific Components (lib/features/x/presentation/widgets/)
**Usage:** Only within that feature
- `SocialLoginButton` - Auth feature only
- `PasswordValidationHint` - Auth feature only
- `AvatarPicker` - Profile feature only
- `ProfileStatItem` - Profile feature only
- Location: `lib/features/[feature]/presentation/widgets/`
- Import: `import 'package:pulso/features/auth/presentation/widgets/auth_widgets.dart';`

### 3. Initialization
The app initializes with:
- ✅ `.env` file loading via `flutter_dotenv`
- ✅ Supabase client initialization
- ✅ Riverpod `ProviderScope` wrapper

## How to Use

### Add Global Widget
1. Create file in `lib/core/widgets/`
2. Export in `lib/core/widgets/widgets.dart`
3. Import with: `import 'package:pulso/core/widgets/widgets.dart';`

### Add Feature Widget
1. Create file in `lib/features/[feature]/presentation/widgets/`
2. Export in barrel file (e.g., `auth_widgets.dart`)
3. Import with: `import 'package:pulso/features/[feature]/presentation/widgets/[feature]_widgets.dart';`

### Add Screen
1. Create file in `lib/features/[feature]/presentation/screens/`
2. Use global and feature widgets as needed

## Adding New Features

For a new feature (e.g., `social`):
```bash
mkdir -p lib/features/social/presentation/screens
mkdir -p lib/features/social/presentation/widgets
mkdir -p lib/features/social/data
mkdir -p lib/features/social/domain
mkdir -p lib/features/social/providers
```

Then follow the same widget organization pattern.
