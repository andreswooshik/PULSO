class FollowSuggestionRecord {
  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  const FollowSuggestionRecord({
    required this.id,
    required this.username,
    required this.displayName,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    this.bio,
    this.avatarUrl,
  });

  factory FollowSuggestionRecord.fromMap(
    Map<String, dynamic> map, {
    required int followersCount,
    required int followingCount,
    required bool isFollowing,
  }) {
    final username = (map['username'] as String?)?.trim();
    final displayName = (map['display_name'] as String?)?.trim();
    final firstName = (map['first_name'] as String?)?.trim();
    final lastName = (map['last_name'] as String?)?.trim();

    return FollowSuggestionRecord(
      id: map['id'] as String? ?? '',
      username: username?.isNotEmpty == true ? username! : 'community_member',
      displayName: _resolveDisplayName(
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        username: username,
      ),
      bio: (map['bio'] as String?)?.trim(),
      avatarUrl: (map['avatar_url'] as String?)?.trim(),
      followersCount: followersCount,
      followingCount: followingCount,
      isFollowing: isFollowing,
    );
  }

  String get initials {
    final parts = displayName
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'CM';
    }
    if (parts.length == 1) {
      final end = parts.first.length >= 2 ? 2 : 1;
      return parts.first.substring(0, end).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _resolveDisplayName({
    required String? displayName,
    required String? firstName,
    required String? lastName,
    required String? username,
  }) {
    if (displayName?.isNotEmpty == true) {
      return displayName!;
    }

    final fullName = [
      if (firstName?.isNotEmpty == true) firstName,
      if (lastName?.isNotEmpty == true) lastName,
    ].join(' ').trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    return username?.isNotEmpty == true ? username! : 'Community Member';
  }
}
