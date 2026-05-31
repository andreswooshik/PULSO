import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/supabase/supabase_provider.dart';
import 'package:pulso/features/feed/data/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.watch(supabaseProvider));
});
