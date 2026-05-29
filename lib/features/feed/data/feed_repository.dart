import 'dart:typed_data';

import 'package:pulso/features/feed/data/feed_post_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedRepository {
  final SupabaseClient _client;
  static const int defaultFeedLimit = 20;

  FeedRepository(this._client);

  Future<List<FeedPostRecord>> fetchPosts({
    int limit = defaultFeedLimit,
  }) async {
    final rows = await _client
        .from('posts')
        .select('id, user_id, image_url, caption, created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    final postMaps = rows.cast<Map<String, dynamic>>();
    final postIds = postMaps
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();
    final userIds = postMaps
        .map((row) => row['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final profilesById = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      final profileRows = await _client
          .from('public_profiles')
          .select('id, username, full_name, avatar_url')
          .inFilter('id', userIds);

      for (final row in profileRows.cast<Map<String, dynamic>>()) {
        final profileId = row['id'] as String?;
        if (profileId != null && profileId.isNotEmpty) {
          profilesById[profileId] = row;
        }
      }
    }

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
          (row) => FeedPostRecord.fromMap({
            ...row,
            'profiles': profilesById[row['user_id'] as String? ?? ''],
          }, commentCount: commentCounts[row['id'] as String? ?? ''] ?? 0),
        )
        .toList();
  }

  Future<void> createPost({
    required String caption,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User must be signed in to create a post.');
    }

    final payload = <String, dynamic>{
      'user_id': userId,
      'caption': caption.trim(),
    };

    if (imageBytes != null && imageFileName != null && imageFileName.isNotEmpty) {
      final fileExt = _imageExtension(imageFileName);
      final storagePath = '$userId/${_uuidV4()}.$fileExt';

      await _client.storage
          .from('posts')
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: fileExt == 'jpg' ? 'image/jpeg' : 'image/$fileExt',
              upsert: true,
            ),
          );

      payload['image_url'] = _client.storage.from('posts').getPublicUrl(storagePath);
    }

    await _client.from('posts').insert(payload);
  }

  String _imageExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (extension == 'png' || extension == 'webp' || extension == 'gif') {
      return extension;
    }

    return 'jpg';
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => DateTime.now().microsecondsSinceEpoch.remainder(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hexByte(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final hex = bytes.map(hexByte).join();

    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }
}
