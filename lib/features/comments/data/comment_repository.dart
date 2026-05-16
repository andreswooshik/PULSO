import 'package:supabase_flutter/supabase_flutter.dart';

class CommentRepository {
  final SupabaseClient _client;

  CommentRepository(this._client);

  Future<List<Map<String, dynamic>>> fetchForPost(String postId) {
    return _client
        .from('comments')
        .select(
          'id, content, created_at, user_id, profiles(username, avatar_url)',
        )
        .eq('post_id', postId)
        .order('created_at');
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to comment.');
    }

    await _client.from('comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  Future<void> deleteComment(String commentId) {
    return _client.from('comments').delete().eq('id', commentId);
  }
}
