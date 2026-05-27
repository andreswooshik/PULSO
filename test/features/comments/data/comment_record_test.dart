import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/comments/data/comment_record.dart';

void main() {
  test('CommentRecord parses nested profile data', () {
    final record = CommentRecord.fromMap({
      'id': 'comment-1',
      'post_id': 'post-1',
      'user_id': 'user-1',
      'content': 'Hello, Pulso!',
      'created_at': '2026-05-27T10:00:00.000Z',
      'profiles': {'username': 'clarence', 'avatar_url': null},
    });

    expect(record.id, 'comment-1');
    expect(record.postId, 'post-1');
    expect(record.username, 'clarence');
    expect(record.initials, 'CL');
  });
}
