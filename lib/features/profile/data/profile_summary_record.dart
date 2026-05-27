class ProfileSummaryRecord {
  final String id;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int postsCount;
  final int followersCount;
  final int followingCount;

  const ProfileSummaryRecord({
    required this.id,
    required this.username,
    required this.displayName,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    this.bio,
    this.avatarUrl,
  });

  String get initials {
    final parts = displayName
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
}
