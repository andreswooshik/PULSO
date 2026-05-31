import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/supabase/supabase_provider.dart';
import 'package:pulso/features/likes/data/like_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return LikeRepository(supabase);
});

final likesRealtimeProvider = Provider<void>((ref) {
  final supabase = ref.watch(supabaseProvider);

  final channel = supabase
      .channel('posts_likes')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'likes',
        callback: (payload) {
          debugPrint('Realtime like update received');
        },
      )
      .subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
  });
});
