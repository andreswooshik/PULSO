import 'package:supabase_flutter/supabase_flutter.dart';

class LikeRepository {
  final SupabaseClient supabase;

  LikeRepository(this.supabase);

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final existing = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await supabase
          .from('likes')
          .delete()
          .eq('id', existing['id']);
    } else {
      await supabase.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  Future<int> getLikeCount(String postId) async {
    final response = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId);

    return response.length;
  }

  Future<bool> hasLiked({
    required String postId,
    required String userId,
  }) async {
    final existing = await supabase
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return existing != null;
  }
}