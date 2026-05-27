import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/profile/data/follow_suggestion_record.dart';

void main() {
  test('FollowSuggestionRecord keeps follow state and counts', () {
    final record = FollowSuggestionRecord.fromMap(
      {
        'id': 'profile-1',
        'username': 'maria',
        'display_name': 'Maria Santos',
        'bio': 'Community organizer',
        'avatar_url': null,
      },
      followersCount: 14,
      followingCount: 8,
      isFollowing: true,
    );

    expect(record.isFollowing, isTrue);
    expect(record.followersCount, 14);
    expect(record.followingCount, 8);
    expect(record.initials, 'MS');
  });
}
