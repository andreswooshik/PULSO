import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/features/comments/presentation/widgets/comments_sheet.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  void _showComments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CommentsSheet(),
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
            tooltip: 'Login',
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.login),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          const _HeroPanel(),
          const SizedBox(height: 14),
          _PostPreviewCard(onCommentsPressed: () => _showComments(context)),
          const SizedBox(height: 14),
          const _FoundationRow(),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8D4C4)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), AppTheme.pearl],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feel the heartbeat of your community',
            style: TextStyle(
              color: AppTheme.midnight,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A shared space for posts, updates, and everyday Filipino connection.',
            style: TextStyle(color: AppTheme.midnight.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _SignalChip(label: 'Bayanihan', icon: Icons.groups_2_outlined),
              SizedBox(width: 8),
              _SignalChip(label: 'Local pulse', icon: Icons.bolt_outlined),
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
        color: AppTheme.pearl,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.72)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.gold, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.midnight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  final VoidCallback onCommentsPressed;

  const _PostPreviewCard({required this.onCommentsPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.gold,
                  child: Text('P', style: TextStyle(color: Colors.black)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'pulso.community',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Foundation preview',
                        style: TextStyle(color: Color(0xFF9FB3D9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: AppTheme.pearl,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD8D4C4)),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppTheme.gold,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Foundation is ready for auth, posts, thumbs-up reactions, comments, and follows.',
            ),
            const SizedBox(height: 10),
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
                const Spacer(),
                Text(
                  '142 thumbs up',
                  style: TextStyle(
                    color: AppTheme.midnight.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          child: _MiniCard(title: 'Posts', icon: Icons.image_outlined),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniCard(title: 'Realtime', icon: Icons.sync_alt),
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
