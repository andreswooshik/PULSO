import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';
import 'package:pulso/features/profile/data/profile_record.dart';
import 'package:pulso/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:pulso/features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
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

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final isUpdating = ref.watch(profileControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authUiProvider.notifier).signOut();
            },
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
                onRefresh: () async {
                  ref.invalidate(currentProfileProvider);
                },
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
                          Text(
                            profileTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
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
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    if (bio != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
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
