import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<String?> uploadAvatar(String userId, XFile imageFile) async {
    try {
      final fileExt = _imageExtension(imageFile.name);
      final fileName = '$userId/${_uuidV4()}.$fileExt';
      final imageBytes = await imageFile.readAsBytes();

      await _client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: fileExt == 'jpg' ? 'image/jpeg' : 'image/$fileExt',
              upsert: true,
            ),
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

  String _imageExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'png' || extension == 'webp') {
      return extension;
    }

    return 'jpg';
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hexByte(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(hexByte).join();

    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }
}

class ProfileRepositoryException implements Exception {
  final String message;

  const ProfileRepositoryException(this.message);

  @override
  String toString() => message;
}
