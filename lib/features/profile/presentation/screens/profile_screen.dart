import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/auth/providers/auth_provider.dart';
import 'package:pulso/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:pulso/features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _editProfileDialog(
    BuildContext context,
    String currentDisplayName,
    String currentBio,
  ) {
    final displayNameController = TextEditingController(
      text: currentDisplayName,
    );
    final bioController = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref
                    .read(profileControllerProvider.notifier)
                    .updateProfile(
                      displayName: displayNameController.text,
                      bio: bioController.text,
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

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
                        onImageSelected: (File imageFile) {
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
                            profile.displayName ??
                                profile.fullName ??
                                profile.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editProfileDialog(
                              context,
                              profile.displayName ?? '',
                              profile.bio ?? '',
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
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        profile.bio!,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
