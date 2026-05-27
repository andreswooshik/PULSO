import 'dart:io';
import 'package:pulso/features/profile/data/profile_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<ProfileRecord?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select(
            '*, posts(id), followers:follows!following_id(follower_id), following:follows!follower_id(following_id)',
          )
          .eq('id', userId)
          .single();

      final postsCount = (response['posts'] as List?)?.length ?? 0;
      final followersCount = (response['followers'] as List?)?.length ?? 0;
      final followingCount = (response['following'] as List?)?.length ?? 0;

      return ProfileRecord.fromJson(response).copyWith(
        postsCount: postsCount,
        followersCount: followersCount,
        followingCount: followingCount,
      );
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<String?> uploadAvatar(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Ensure the 'avatars' bucket exists in Supabase
      await _client.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrlResponse = _client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      return imageUrlResponse;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }
}
