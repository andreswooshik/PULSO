class FeedPostRecord {
  final String id;
  final String userId;
  final String caption;
  final String? imageUrl;
  final DateTime createdAt;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int commentCount;

  const FeedPostRecord({
    required this.id,
    required this.userId,
    required this.caption,
    required this.createdAt,
    required this.username,
    required this.displayName,
    required this.commentCount,
    this.imageUrl,
    this.avatarUrl,
  });

  factory FeedPostRecord.fromMap(
    Map<String, dynamic> map, {
    int commentCount = 0,
  }) {
    final profile = _profileMap(map['profiles']);
    final username = (profile?['username'] as String?)?.trim();
    final fullName = (profile?['full_name'] as String?)?.trim();
    final displayName = (profile?['display_name'] as String?)?.trim();
    final firstName = (profile?['first_name'] as String?)?.trim();
    final lastName = (profile?['last_name'] as String?)?.trim();

    return FeedPostRecord(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      caption: (map['caption'] as String?)?.trim() ?? '',
      imageUrl: (map['image_url'] as String?)?.trim(),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      username: username?.isNotEmpty == true ? username! : 'community_member',
      displayName: _resolveDisplayName(
        fullName: fullName,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        username: username,
      ),
      avatarUrl: (profile?['avatar_url'] as String?)?.trim(),
      commentCount: commentCount,
    );
  }

  String get initials {
    final source = displayName.trim().isNotEmpty ? displayName : username;
    final parts = source
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'P';
    }
    if (parts.length == 1) {
      final end = parts.first.length >= 2 ? 2 : 1;
      return parts.first.substring(0, end).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _resolveDisplayName({
    required String? fullName,
    required String? displayName,
    required String? firstName,
    required String? lastName,
    required String? username,
  }) {
    if (fullName?.isNotEmpty == true) {
      return fullName!;
    }

    if (displayName?.isNotEmpty == true) {
      return displayName!;
    }

    final nameParts = [
      if (firstName?.isNotEmpty == true) firstName,
      if (lastName?.isNotEmpty == true) lastName,
    ];

    if (nameParts.isNotEmpty) {
      return nameParts.join(' ');
    }

    return username?.isNotEmpty == true ? username! : 'Community Member';
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
