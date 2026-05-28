import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/like_provider.dart';

class LikeButton extends ConsumerStatefulWidget {
  final String postId;
  final String userId;

  const LikeButton({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  bool hasLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    loadLikeData();
  }

  Future<void> loadLikeData() async {
    final repository = ref.read(likeRepositoryProvider);

    final liked = await repository.hasLiked(
      postId: widget.postId,
      userId: widget.userId,
    );

    final count = await repository.getLikeCount(widget.postId);

    if (mounted) {
      setState(() {
        hasLiked = liked;
        likeCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(likesRealtimeProvider);

    return Row(
      children: [
        IconButton(
          icon: Icon(
            hasLiked
                ? Icons.favorite
                : Icons.favorite_border,
            color: hasLiked ? Colors.red : null,
          ),
          onPressed: () async {
            final repository = ref.read(likeRepositoryProvider);

            await repository.toggleLike(
              postId: widget.postId,
              userId: widget.userId,
            );

            await loadLikeData();
          },
        ),

        Text('$likeCount'),
      ],
    );
  }
}