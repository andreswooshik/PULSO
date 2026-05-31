import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/core/supabase/supabase_provider.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';
import 'package:pulso/features/profile/data/profile_record.dart';
import 'package:pulso/features/profile/data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

final currentProfileProvider = FutureProvider<ProfileRecord?>((ref) async {
  final authState = ref.watch(authUiProvider);
  final userId =
      authState.userId ?? ref.watch(supabaseProvider).auth.currentUser?.id;

  if (userId == null) {
    return null;
  }

  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile(userId);
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<void>>((ref) {
      return ProfileController(ref);
    });

class ProfileController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ProfileController(this._ref) : super(const AsyncData(null));

  Future<bool> updateProfile({
    required String userId,
    required String currentUsername,
    String? username,
    String? bio,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = _ref.read(profileRepositoryProvider);
      await repo.updateProfile(
        userId: userId,
        username: username,
        currentUsername: currentUsername,
        bio: bio,
      );

      _ref.invalidate(currentProfileProvider);
      await _ref.read(currentProfileProvider.future);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> uploadAndUpdateAvatar(XFile imageFile) async {
    state = const AsyncLoading();
    try {
      final userId = _ref.read(authUiProvider).userId;
      if (userId == null) throw Exception('Not authenticated');

      final repo = _ref.read(profileRepositoryProvider);
      final avatarUrl = await repo.uploadAvatar(userId, imageFile);

      if (avatarUrl != null) {
        await repo.updateProfile(userId: userId, avatarUrl: avatarUrl);
        _ref.invalidate(currentProfileProvider);
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
