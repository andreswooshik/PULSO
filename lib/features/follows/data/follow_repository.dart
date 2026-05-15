import 'package:supabase_flutter/supabase_flutter.dart';

class FollowRepository {
  final SupabaseClient _client;

  FollowRepository(this._client);

  Future<void> follow(String followingId) async {
    final followerId = _client.auth.currentUser?.id;
    if (followerId == null) {
      throw StateError('User must be signed in to follow.');
    }

    await _client.from('follows').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollow(String followingId) async {
    final followerId = _client.auth.currentUser?.id;
    if (followerId == null) {
      throw StateError('User must be signed in to unfollow.');
    }

    await _client
        .from('follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  Future<bool> isFollowing(String followingId) async {
    final followerId = _client.auth.currentUser?.id;
    if (followerId == null) {
      return false;
    }

    final rows = await _client
        .from('follows')
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .limit(1);

    return rows.isNotEmpty;
  }
}
