import 'package:pulso/features/feed/data/feed_post_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedRepository {
  final SupabaseClient _client;

  FeedRepository(this._client);

  Future<List<FeedPostRecord>> fetchPosts() async {
    final rows = await _client
        .from('posts')
        .select(
          'id, user_id, image_url, caption, created_at, '
          'profiles(username, display_name, first_name, last_name, avatar_url)',
        )
        .order('created_at', ascending: false);

    final postMaps = rows.cast<Map<String, dynamic>>();
    final postIds = postMaps
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();

    final commentCounts = <String, int>{};
    if (postIds.isNotEmpty) {
      final countRows = await _client
          .from('post_comment_counts')
          .select('post_id, comment_count')
          .inFilter('post_id', postIds);

      for (final row in countRows) {
        final map = row;
        commentCounts[map['post_id'] as String? ?? ''] =
            map['comment_count'] as int? ?? 0;
      }
    }

    return postMaps
        .map(
          (row) => FeedPostRecord.fromMap(
            row,
            commentCount: commentCounts[row['id'] as String? ?? ''] ?? 0,
          ),
        )
        .toList();
  }

  Future<void> createPost({required String caption}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to create a post.');
    }

    await _client.from('posts').insert({
      'user_id': userId,
      'caption': caption.trim(),
    });
  }
}
