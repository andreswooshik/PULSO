import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/feed/data/feed_post_record.dart';

void main() {
  test('FeedPostRecord falls back to first and last name for display', () {
    final record = FeedPostRecord.fromMap({
      'id': 'post-1',
      'user_id': 'user-1',
      'caption': 'Magandang araw!',
      'created_at': '2026-05-27T10:00:00.000Z',
      'profiles': {
        'username': 'juan_d',
        'display_name': null,
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'avatar_url': null,
      },
    });

    expect(record.displayName, 'Juan Dela Cruz');
    expect(record.username, 'juan_d');
    expect(record.initials, 'JC');
  });
}
