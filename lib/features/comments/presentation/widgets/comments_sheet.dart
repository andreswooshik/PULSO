import 'package:flutter/material.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/features/comments/data/comment_record.dart';
import 'package:pulso/features/comments/data/comment_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  final String postLabel;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.postLabel,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late final SupabaseClient _client;
  late final CommentRepository _repository;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  RealtimeChannel? _channel;

  List<CommentRecord> _comments = const [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;
    _repository = CommentRepository(_client);
    _loadComments();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    final channel = _channel;
    if (channel != null) {
      _client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final comments = await _repository.fetchForPost(widget.postId);
      if (!mounted) {
        return;
      }

      setState(() {
        _comments = comments;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not load comments right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToRealtime() {
    _channel = _client
        .channel('comments:${widget.postId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: widget.postId,
          ),
          callback: (_) {
            if (mounted) {
              _loadComments();
            }
          },
        )
        .subscribe();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _repository.addComment(postId: widget.postId, content: content);
      _commentController.clear();
      _commentFocusNode.requestFocus();
      await _loadComments();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not send your comment. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      await _loadComments();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the comment.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _client.auth.currentUser?.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pearl,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            color: AppTheme.midnight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.postLabel,
                          style: TextStyle(
                            color: AppTheme.midnight.withValues(alpha: 0.62),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.royalBlue.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sync,
                            size: 14,
                            color: AppTheme.royalBlue,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: AppTheme.royalBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppTheme.midnight),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD0D5DD)),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _InlineMessage(message: _errorMessage!),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadComments,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                      ? ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                          children: const [
                            Icon(
                              Icons.mode_comment_outlined,
                              size: 44,
                              color: AppTheme.royalBlue,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No comments yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.midnight,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start the thread and make this post feel alive.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF667085),
                                height: 1.4,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return _CommentTile(
                              comment: comment,
                              isOwnComment: currentUserId == comment.userId,
                              onDelete: () => _deleteComment(comment.id),
                            );
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemCount: _comments.length,
                        ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.royalBlue.withValues(
                          alpha: 0.14,
                        ),
                        foregroundColor: AppTheme.royalBlue,
                        child: Text(
                          _currentUserInitials(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            suffixIcon: IconButton(
                              tooltip: 'Send',
                              onPressed:
                                  _isSubmitting ||
                                      _commentController.text.trim().isEmpty
                                  ? null
                                  : _submitComment,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _submitComment(),
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

  String _currentUserInitials() {
    final username = _client.auth.currentUser?.userMetadata?['username'];
    if (username is String && username.trim().isNotEmpty) {
      final clean = username.trim();
      final end = clean.length >= 2 ? 2 : 1;
      return clean.substring(0, end).toUpperCase();
    }
    return 'YO';
  }
}

class _CommentTile extends StatelessWidget {
  final CommentRecord comment;
  final bool isOwnComment;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwnComment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.royalBlue.withValues(alpha: 0.14),
          foregroundColor: AppTheme.royalBlue,
          child: Text(
            comment.initials,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.username,
                        style: const TextStyle(
                          color: AppTheme.midnight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isOwnComment)
                      PopupMenuButton<String>(
                        tooltip: 'Comment options',
                        onSelected: (_) => onDelete(),
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete comment'),
                          ),
                        ],
                        child: const Icon(
                          Icons.more_horiz,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: AppTheme.midnight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _timeAgo(comment.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 16,
                      color: AppTheme.royalBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt.toLocal());

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[createdAt.month - 1]} ${createdAt.day}';
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;

  const _InlineMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.midnight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
