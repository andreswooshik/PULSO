import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/core/supabase/supabase_provider.dart';
import 'package:pulso/features/comments/data/comment_repository.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(ref.watch(supabaseProvider));
});
