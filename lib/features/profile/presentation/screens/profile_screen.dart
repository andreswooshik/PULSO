import 'package:flutter/material.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';
import 'package:pulso/features/follows/data/follow_repository.dart';
import 'package:pulso/features/profile/data/follow_suggestion_record.dart';
import 'package:pulso/features/profile/data/profile_repository.dart';
import 'package:pulso/features/profile/data/profile_summary_record.dart';
import 'package:pulso/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final ProfileRepository _profileRepository;
  late final FollowRepository _followRepository;

  ProfileSummaryRecord? _profile;
  List<FollowSuggestionRecord> _suggestions = const [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _busyProfileIds = <String>{};

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _profileRepository = ProfileRepository(client);
    _followRepository = FollowRepository(client);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileRepository.fetchCurrentProfile();
      final suggestions = await _profileRepository.fetchDiscoverProfiles();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _suggestions = suggestions;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Could not load your profile details.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(FollowSuggestionRecord profile) async {
    setState(() {
      _busyProfileIds.add(profile.id);
    });

    try {
      if (profile.isFollowing) {
        await _followRepository.unfollow(profile.id);
      } else {
        await _followRepository.follow(profile.id);
      }
      await _loadProfileData();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profile.isFollowing
                ? 'Could not update follow state right now.'
                : 'Could not follow this account right now.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyProfileIds.remove(profile.id);
        });
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(authUiProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _loadProfileData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null) ...[
              _InlineMessage(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_profile != null) ...[
              _ProfileHeader(profile: _profile!),
              const SizedBox(height: 18),
              _DiscoverSection(
                suggestions: _suggestions,
                busyProfileIds: _busyProfileIds,
                onToggleFollow: _toggleFollow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileSummaryRecord profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.royalBlue.withValues(alpha: 0.14),
            foregroundColor: AppTheme.royalBlue,
            child: Text(
              profile.initials,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '@${profile.username}',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ProfileStatItem(
                label: 'Posts',
                value: profile.postsCount.toString(),
              ),
              ProfileStatItem(
                label: 'Followers',
                value: profile.followersCount.toString(),
              ),
              ProfileStatItem(
                label: 'Following',
                value: profile.followingCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscoverSection extends StatelessWidget {
  final List<FollowSuggestionRecord> suggestions;
  final Set<String> busyProfileIds;
  final Future<void> Function(FollowSuggestionRecord profile) onToggleFollow;

  const _DiscoverSection({
    required this.suggestions,
    required this.busyProfileIds,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discover people',
          style: TextStyle(
            color: AppTheme.midnight,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Follow other community members and watch your counts update here.',
          style: TextStyle(color: Color(0xFF667085), height: 1.4),
        ),
        const SizedBox(height: 14),
        if (suggestions.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: const Text(
              'No other profiles yet. Once your teammates sign up, they will appear here.',
              style: TextStyle(height: 1.4),
            ),
          )
        else
          ...suggestions.map(
            (profile) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DiscoverCard(
                profile: profile,
                isBusy: busyProfileIds.contains(profile.id),
                onToggleFollow: () => onToggleFollow(profile),
              ),
            ),
          ),
      ],
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final FollowSuggestionRecord profile;
  final bool isBusy;
  final VoidCallback onToggleFollow;

  const _DiscoverCard({
    required this.profile,
    required this.isBusy,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.gold.withValues(alpha: 0.2),
                foregroundColor: AppTheme.indigo,
                child: Text(
                  profile.initials,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.username}',
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: isBusy ? null : onToggleFollow,
                style: FilledButton.styleFrom(
                  backgroundColor: profile.isFollowing
                      ? const Color(0xFFE4E7EC)
                      : AppTheme.royalBlue,
                  foregroundColor: profile.isFollowing
                      ? AppTheme.midnight
                      : Colors.white,
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(profile.isFollowing ? 'Following' : 'Follow'),
              ),
            ],
          ),
          if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                profile.bio!,
                style: const TextStyle(height: 1.35),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                label: 'Followers',
                value: profile.followersCount.toString(),
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Following',
                value: profile.followingCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.midnight,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
