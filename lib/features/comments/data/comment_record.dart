class CommentRecord {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String username;
  final String? avatarUrl;

  const CommentRecord({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.username,
    this.avatarUrl,
  });

  factory CommentRecord.fromMap(Map<String, dynamic> map) {
    final profile = _profileMap(map['public_profiles'] ?? map['profiles']);
    final username = (profile?['username'] as String?)?.trim();

    return CommentRecord(
      id: map['id'] as String? ?? '',
      postId: map['post_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      username: username?.isNotEmpty == true ? username! : 'community_member',
      avatarUrl: (profile?['avatar_url'] as String?)?.trim(),
    );
  }

  factory CommentRecord.fromJson(Map<String, dynamic> json) {
    return CommentRecord.fromMap(json);
  }

  String get initials {
    final source = username.replaceAll('_', ' ').trim();
    if (source.isEmpty) {
      return 'CM';
    }

    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      final end = parts.first.length >= 2 ? 2 : 1;
      return parts.first.substring(0, end).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Map<String, dynamic>? _profileMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }
}
