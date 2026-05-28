import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/like_repository.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return LikeRepository(supabase);
});

final likesRealtimeProvider = Provider<void>((ref) {
  final supabase = Supabase.instance.client;

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
