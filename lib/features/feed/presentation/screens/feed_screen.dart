import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/core/widgets/widgets.dart';
import 'package:pulso/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:pulso/features/feed/data/feed_post_record.dart';
import 'package:pulso/features/feed/data/feed_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final FeedRepository _repository;

  List<FeedPostRecord> _posts = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = FeedRepository(Supabase.instance.client);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await _repository.fetchPosts();
      if (!mounted) {
        return;
      }

      setState(() {
        _posts = posts;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not load the feed right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showComments(FeedPostRecord post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(
        postId: post.id,
        postLabel: '@${post.username}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pulso',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh feed',
            onPressed: _loadPosts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            const _HeroPanel(),
            const SizedBox(height: 14),
            if (_errorMessage != null) ...[
              InlineMessage(message: _errorMessage!),
              const SizedBox(height: 14),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_posts.isEmpty)
              const _EmptyFeedState()
            else
              ..._posts.expand(
                (post) => [
                  _PostCard(
                    post: post,
                    onCommentsPressed: () => _showComments(post),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            const _FoundationRow(),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF21385C)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07101F), Color(0xFF10284C), Color(0xFF10131A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feel the heartbeat of your community',
            style: TextStyle(
              color: AppTheme.sampaguita,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comments now open into live threads, and follows are ready from the profile area.',
            style: TextStyle(color: AppTheme.pearl.withValues(alpha: 0.76)),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _SignalChip(label: 'Bayanihan', icon: Icons.groups_2_outlined),
              SizedBox(width: 8),
              _SignalChip(label: 'Realtime', icon: Icons.sync),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SignalChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.gold, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final FeedPostRecord post;
  final VoidCallback onCommentsPressed;

  const _PostCard({required this.post, required this.onCommentsPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.black,
                  child: Text(
                    post.initials,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '@${post.username} - ${_formatTimestamp(post.createdAt)}',
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.caption.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                post.caption,
                style: const TextStyle(
                  color: AppTheme.midnight,
                  height: 1.42,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E7EC)),
              ),
              child: post.imageUrl == null || post.imageUrl!.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: AppTheme.royalBlue,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Text update',
                            style: TextStyle(
                              color: AppTheme.midnight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(post.imageUrl!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: 'Thumbs up',
                  onPressed: () {},
                  icon: const Icon(Icons.thumb_up_alt_outlined),
                ),
                IconButton(
                  tooltip: 'Comments',
                  onPressed: onCommentsPressed,
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                Text(
                  '${post.commentCount}',
                  style: const TextStyle(
                    color: AppTheme.midnight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  post.commentCount == 1
                      ? '1 live comment'
                      : '${post.commentCount} live comments',
                  style: TextStyle(
                    color: AppTheme.midnight.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) {
      return 'now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }
    return '${difference.inDays}d';
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, size: 44, color: AppTheme.royalBlue),
          const SizedBox(height: 14),
          const Text(
            'No posts yet',
            style: TextStyle(
              color: AppTheme.midnight,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create the first post so your comment threads and follow activity have somewhere to gather.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF667085), height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.createPost),
            icon: const Icon(Icons.add),
            label: const Text('Create a post'),
          ),
        ],
      ),
    );
  }
}

class _FoundationRow extends StatelessWidget {
  const _FoundationRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MiniCard(title: 'Comments', icon: Icons.mode_comment_outlined),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniCard(title: 'Follows', icon: Icons.person_add_alt_1),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _MiniCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.gold),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
