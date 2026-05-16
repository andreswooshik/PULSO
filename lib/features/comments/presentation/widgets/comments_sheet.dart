import 'package:flutter/material.dart';
import 'package:pulso/core/theme/app_theme.dart';

class CommentsSheet extends StatelessWidget {
  const CommentsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pearl,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 10),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD8D4C4)),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: const [
                    _CommentTile(
                      initials: 'EW',
                      username: 'emmawilson',
                      comment: 'This is absolutely beautiful!',
                      meta: '2h   142 thumbs up',
                      liked: false,
                    ),
                    _CommentTile(
                      initials: 'LB',
                      username: 'lucasbrown',
                      comment:
                          'Love the energy in this photo. Where was this taken?',
                      meta: '3h   89 thumbs up',
                      liked: true,
                    ),
                    _CommentTile(
                      initials: 'AV',
                      username: 'avamartinez',
                      comment: 'Incredible moment captured!',
                      meta: '5h   56 thumbs up',
                      liked: false,
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.gold,
                        child: Text(
                          'P',
                          style: TextStyle(color: AppTheme.midnight),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            suffixIcon: IconButton(
                              tooltip: 'Send',
                              onPressed: () {},
                              icon: const Icon(Icons.send_outlined),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String initials;
  final String username;
  final String comment;
  final String meta;
  final bool liked;

  const _CommentTile({
    required this.initials,
    required this.username,
    required this.comment,
    required this.meta,
    required this.liked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.royalBlue,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppTheme.midnight),
                    children: [
                      TextSpan(
                        text: '$username  ',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: comment),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  meta,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
            color: liked ? AppTheme.royalBlue : AppTheme.midnight,
            size: 20,
          ),
        ],
      ),
    );
  }
}
