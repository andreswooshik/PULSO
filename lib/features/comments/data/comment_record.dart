class CommentRecord {
  final String id;
  final String content;
  final DateTime createdAt;
  final String userId;
  final String username;
  final String? avatarUrl;

  const CommentRecord({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  factory CommentRecord.fromJson(Map<String, dynamic> json) {
    final profile = (json['profiles'] as Map<String, dynamic>?) ?? {};

    return CommentRecord(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
      username: (profile['username'] as String?) ?? '',
      avatarUrl: profile['avatar_url'] as String?,
    );
  }
}
