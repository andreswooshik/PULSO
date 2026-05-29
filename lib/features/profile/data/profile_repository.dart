import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/features/profile/data/follow_suggestion_record.dart';
import 'package:pulso/features/profile/data/profile_record.dart';
import 'package:pulso/features/profile/data/profile_summary_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<ProfileSummaryRecord> fetchCurrentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to view a profile.');
    }

    final row = await _client
        .from('profiles')
        .select(
          'id, username, display_name, first_name, last_name, bio, avatar_url',
        )
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      throw StateError('Profile not found.');
    }

    Map<String, dynamic>? countsRow;
    try {
      countsRow = await _client
          .from('profile_follow_counts')
          .select('followers_count, following_count')
          .eq('profile_id', userId)
          .maybeSingle();
    } catch (error) {
      debugPrint('Could not load profile follow counts: $error');
      countsRow = null;
    }

    Map<String, dynamic>? postCountsRow;
    try {
      postCountsRow = await _client
          .from('profile_post_counts')
          .select('posts_count')
          .eq('profile_id', userId)
          .maybeSingle();
    } catch (error) {
      debugPrint('Could not load profile post counts: $error');
      postCountsRow = null;
    }
    final username = (row['username'] as String?)?.trim();
    final displayName = (row['display_name'] as String?)?.trim();
    final firstName = (row['first_name'] as String?)?.trim();
    final lastName = (row['last_name'] as String?)?.trim();

    return ProfileSummaryRecord(
      id: row['id'] as String? ?? '',
      username: username?.isNotEmpty == true ? username! : 'community_member',
      displayName: _resolveDisplayName(
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        username: username,
      ),
      bio: (row['bio'] as String?)?.trim(),
      avatarUrl: (row['avatar_url'] as String?)?.trim(),
      postsCount: postCountsRow?['posts_count'] as int? ?? 0,
      followersCount: countsRow?['followers_count'] as int? ?? 0,
      followingCount: countsRow?['following_count'] as int? ?? 0,
    );
  }

  Future<List<FollowSuggestionRecord>> fetchDiscoverProfiles({
    int limit = 8,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to view profiles.');
    }

    final rows = await _client
        .from('profiles')
        .select(
          'id, username, display_name, first_name, last_name, bio, avatar_url, created_at',
        )
        .neq('id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final profileMaps = rows.cast<Map<String, dynamic>>();
    if (profileMaps.isEmpty) {
      return const [];
    }

    final ids = profileMaps
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();

    final followingRows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId)
        .inFilter('following_id', ids);

    final followingIds = followingRows
        .map((row) => row['following_id'] as String?)
        .whereType<String>()
        .toSet();

    final countByProfileId = <String, Map<String, int>>{};
    try {
      final countRows = await _client
          .from('profile_follow_counts')
          .select('profile_id, followers_count, following_count')
          .inFilter('profile_id', ids);

      for (final row in countRows) {
        final map = row;
        countByProfileId[map['profile_id'] as String? ?? ''] = {
          'followers_count': map['followers_count'] as int? ?? 0,
          'following_count': map['following_count'] as int? ?? 0,
        };
      }
    } catch (error) {
      debugPrint('Could not load discover profile counts: $error');
    }

    return profileMaps
        .map(
          (row) => FollowSuggestionRecord.fromMap(
            row,
            followersCount:
                countByProfileId[row['id'] as String? ?? '']?['followers_count'] ??
                0,
            followingCount:
                countByProfileId[row['id'] as String? ?? '']?['following_count'] ??
                0,
            isFollowing: followingIds.contains(row['id']),
          ),
        )
        .toList();
  }

  Future<ProfileRecord?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('id, username, full_name, bio, avatar_url')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    Map<String, dynamic>? followCountsRow;
    try {
      followCountsRow = await _client
          .from('profile_follow_counts')
          .select('followers_count, following_count')
          .eq('profile_id', userId)
          .maybeSingle();
    } catch (error) {
      debugPrint('Could not load profile follow counts: $error');
      followCountsRow = null;
    }

    Map<String, dynamic>? postCountsRow;
    try {
      postCountsRow = await _client
          .from('profile_post_counts')
          .select('posts_count')
          .eq('profile_id', userId)
          .maybeSingle();
    } catch (error) {
      debugPrint('Could not load profile post counts: $error');
      postCountsRow = null;
    }

    return ProfileRecord.fromJson({
      ...response,
      'followers_count': followCountsRow?['followers_count'] as int? ?? 0,
      'following_count': followCountsRow?['following_count'] as int? ?? 0,
      'posts_count': postCountsRow?['posts_count'] as int? ?? 0,
    });
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
      final imageBytes = await imageFile.readAsBytes();
      final fileExt = _imageExtension(imageFile.name);
      final mimeType = switch (fileExt) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      return 'data:$mimeType;base64,${base64Encode(imageBytes)}';
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  String _imageExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'png' || extension == 'webp' || extension == 'gif') {
      return extension;
    }

    return 'jpg';
  }

  static String _resolveDisplayName({
    required String? displayName,
    required String? firstName,
    required String? lastName,
    required String? username,
  }) {
    if (displayName?.isNotEmpty == true) {
      return displayName!;
    }

    final fullName = [
      if (firstName?.isNotEmpty == true) firstName,
      if (lastName?.isNotEmpty == true) lastName,
    ].join(' ').trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return username?.isNotEmpty == true ? username! : 'Community Member';
  }

}

class ProfileRepositoryException implements Exception {
  final String message;

  const ProfileRepositoryException(this.message);

  @override
  String toString() => message;
}
