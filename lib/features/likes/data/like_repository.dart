import 'package:supabase_flutter/supabase_flutter.dart';

class LikeRepository {
  final SupabaseClient _client;

  LikeRepository(this._client);

  Future<void> like(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to like posts.');
    }

    await _client.from('likes').insert({'post_id': postId, 'user_id': userId});
  }

  Future<void> unlike(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to unlike posts.');
    }

    await _client
        .from('likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }
}
