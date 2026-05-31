import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/supabase/supabase_provider.dart';
import 'package:pulso/features/follows/data/follow_repository.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(ref.watch(supabaseProvider));
});
