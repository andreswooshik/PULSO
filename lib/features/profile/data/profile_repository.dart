import 'package:pulso/features/profile/data/follow_suggestion_record.dart';
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

    final countsRow = await _client
        .from('profile_follow_counts')
        .select('followers_count, following_count')
        .eq('profile_id', userId)
        .maybeSingle();

    final postCountsRow = await _client
        .from('profile_post_counts')
        .select('posts_count')
        .eq('profile_id', userId)
        .maybeSingle();
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

    final countRows = await _client
        .from('profile_follow_counts')
        .select('profile_id, followers_count, following_count')
        .inFilter('profile_id', ids);

    final countByProfileId = <String, Map<String, int>>{};
    for (final row in countRows) {
      final map = row;
      countByProfileId[map['profile_id'] as String? ?? ''] = {
        'followers_count': map['followers_count'] as int? ?? 0,
        'following_count': map['following_count'] as int? ?? 0,
      };
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
