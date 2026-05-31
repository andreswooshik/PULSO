import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/core/widgets/widgets.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';
import 'package:pulso/features/follows/data/follow_repository.dart';
import 'package:pulso/features/follows/providers/follow_provider.dart';
import 'package:pulso/features/profile/data/follow_suggestion_record.dart';
import 'package:pulso/features/profile/data/profile_record.dart';
import 'package:pulso/features/profile/data/profile_repository.dart';
import 'package:pulso/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:pulso/features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final ProfileRepository _profileRepository;
  late final FollowRepository _followRepository;

  List<FollowSuggestionRecord> _suggestions = const [];
  bool _isSuggestionsLoading = true;
  String? _suggestionsError;
  final Set<String> _busyProfileIds = <String>{};

  @override
  void initState() {
    super.initState();
    _profileRepository = ref.read(profileRepositoryProvider);
    _followRepository = ref.read(followRepositoryProvider);
    _loadSuggestions();
  }

  String _profileTitle(ProfileRecord profile) {
    final fullName = profile.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    return profile.username;
  }

  String? _profileBio(ProfileRecord profile) {
    final bio = profile.bio?.trim();
    if (bio == null || bio.isEmpty) {
      return null;
    }

    return bio;
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSuggestionsLoading = true;
      _suggestionsError = null;
    });

    try {
      final suggestions = await _profileRepository.fetchDiscoverProfiles();
      if (!mounted) {
        return;
      }

      setState(() {
        _suggestions = suggestions;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _suggestionsError = 'Could not load follow suggestions right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSuggestionsLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    ref.invalidate(currentProfileProvider);
    await Future.wait([
      ref.read(currentProfileProvider.future),
      _loadSuggestions(),
    ]);
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
      await _refreshAll();
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

  Future<void> _saveProfileChanges({
    required String profileId,
    required String currentUsername,
    required BuildContext dialogContext,
    required TextEditingController usernameController,
    required TextEditingController bioController,
  }) async {
    final saved = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          userId: profileId,
          currentUsername: currentUsername,
          username: usernameController.text.trim(),
          bio: bioController.text.trim(),
        );

    if (!mounted || !dialogContext.mounted) {
      return;
    }

    if (saved) {
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      await _refreshAll();
      return;
    }

    final error = ref.read(profileControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.toString() ?? 'Profile update failed')),
    );
  }

  Future<void> _editProfileDialog(
    BuildContext context,
    String profileId,
    String currentUsername,
    String currentBio,
  ) async {
    final usernameController = TextEditingController(text: currentUsername);
    final bioController = TextEditingController(text: currentBio);

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => _saveProfileChanges(
                  profileId: profileId,
                  currentUsername: currentUsername,
                  dialogContext: dialogContext,
                  usernameController: usernameController,
                  bioController: bioController,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    } finally {
      usernameController.dispose();
      bioController.dispose();
    }
  }

  Future<void> _signOut() async {
    await ref.read(authUiProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isUpdating = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to load profile. Error:\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          final profileTitle = _profileTitle(profile);
          final bio = _profileBio(profile);

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refreshAll,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Center(
                      child: AvatarPicker(
                        currentImageUrl: profile.avatarUrl,
                        onImageSelected: (XFile imageFile) {
                          ref
                              .read(profileControllerProvider.notifier)
                              .uploadAndUpdateAvatar(imageFile);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              profileTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editProfileDialog(
                              context,
                              profile.id,
                              profile.username,
                              bio ?? '',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (profile.username.isNotEmpty)
                      Center(
                        child: Text(
                          '@${profile.username}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    if (bio != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
                    _DiscoverSection(
                      suggestions: _suggestions,
                      isLoading: _isSuggestionsLoading,
                      errorMessage: _suggestionsError,
                      busyProfileIds: _busyProfileIds,
                      onToggleFollow: _toggleFollow,
                      onRetry: _loadSuggestions,
                    ),
                  ],
                ),
              ),
              if (isUpdating)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DiscoverSection extends StatelessWidget {
  final List<FollowSuggestionRecord> suggestions;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> busyProfileIds;
  final Future<void> Function(FollowSuggestionRecord profile) onToggleFollow;
  final Future<void> Function() onRetry;

  const _DiscoverSection({
    required this.suggestions,
    required this.isLoading,
    required this.errorMessage,
    required this.busyProfileIds,
    required this.onToggleFollow,
    required this.onRetry,
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
        if (errorMessage != null) ...[
          InlineMessage(message: errorMessage!),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ] else if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (suggestions.isEmpty)
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
                child: const FaIcon(FontAwesomeIcons.user, size: 16),
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
              child: Text(profile.bio!, style: const TextStyle(height: 1.35)),
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
