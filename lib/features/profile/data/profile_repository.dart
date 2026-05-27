import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pulso/features/profile/data/profile_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<ProfileRecord?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select(
          '*, posts!posts_user_id_fkey(id), followers:follows!following_id(follower_id), following:follows!follower_id(following_id)',
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
  }

  Future<void> updateProfile({
    required String userId,
    String? username,
    String? currentUsername,
    String? bio,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null) {
      updates['username'] = await _availableUsername(
        username: username,
        currentUsername: currentUsername,
      );
    }
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<String> _availableUsername({
    required String username,
    String? currentUsername,
  }) async {
    final cleanUsername = _normalizeUsername(username);
    final cleanCurrentUsername = _normalizeUsername(currentUsername ?? '');

    if (cleanUsername.isEmpty) {
      throw const ProfileRepositoryException('Username is required.');
    }

    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(cleanUsername)) {
      throw const ProfileRepositoryException(
        'Username must be 3-24 characters and use only letters, numbers, or underscores.',
      );
    }

    if (cleanUsername == cleanCurrentUsername) {
      return cleanUsername;
    }

    final result = await _client.rpc(
      'is_username_available',
      params: {'requested_username': cleanUsername},
    );

    if (result == true) {
      return cleanUsername;
    }

    throw const ProfileRepositoryException(
      'Username is already taken. Choose another username.',
    );
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
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
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }
}

class ProfileRepositoryException implements Exception {
  final String message;

  const ProfileRepositoryException(this.message);

  @override
  String toString() => message;
}
