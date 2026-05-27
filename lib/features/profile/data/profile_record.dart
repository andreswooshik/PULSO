import 'package:flutter/foundation.dart';

@immutable
class ProfileRecord {
  final String id;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  const ProfileRecord({
    required this.id,
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  factory ProfileRecord.fromJson(Map<String, dynamic> json) {
    return ProfileRecord(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? 'unknown',
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      // We will need to compute these or join them
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
    };
  }

  ProfileRecord copyWith({
    String? id,
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) {
    return ProfileRecord(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
    );
  }
}
