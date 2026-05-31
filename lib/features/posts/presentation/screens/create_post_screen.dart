import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
import 'package:pulso/core/widgets/widgets.dart';
import 'package:pulso/features/feed/data/feed_repository.dart';
import 'package:pulso/features/feed/providers/feed_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  late final FeedRepository _repository;

  XFile? _pickedImage;
  Uint8List? _previewBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(feedRepositoryProvider);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (image == null) {
        return;
      }

      final previewBytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _pickedImage = image;
        _previewBytes = previewBytes;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not add image: $error')));
      }
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _previewBytes = null;
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _repository.createPost(
        caption: _captionController.text,
        imageBytes: _previewBytes,
        imageFileName: _pickedImage?.name,
      );
      if (!mounted) {
        return;
      }

      final message = _previewBytes == null
          ? 'Post published to the community feed.'
          : 'Post published with the image saved in Supabase storage.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (mounted) {
        setState(() {
          _captionController.clear();
          _pickedImage = null;
          _previewBytes = null;
        });
      }
      context.go(AppRoutes.feed);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not publish your post yet.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Share a community update',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Caption posts are live now. Image selection is uploaded to Supabase storage and saved with the post.',
              style: TextStyle(color: Color(0xFF667085), height: 1.4),
            ),
            const SizedBox(height: 20),
            _ImageComposer(
              previewBytes: _previewBytes,
              onChooseImage: _chooseImage,
              onRemoveImage: _removeImage,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _captionController,
              label: 'Caption',
              hint: 'Share something with the community',
              minLines: 1,
              maxLines: 5,
              validator: _validateCaption,
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: _isSubmitting ? 'Publishing...' : 'Post',
              onPressed: _submit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }

  String? _validateCaption(String? value) {
    final caption = value?.trim() ?? '';
    if (caption.isEmpty) {
      return 'Caption is required.';
    }
    if (caption.length > 500) {
      return 'Caption must be 500 characters or less.';
    }
    return null;
  }
}

class _ImageComposer extends StatelessWidget {
  final Uint8List? previewBytes;
  final VoidCallback onChooseImage;
  final VoidCallback onRemoveImage;

  const _ImageComposer({
    required this.previewBytes,
    required this.onChooseImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = previewBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD4DAE8)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.memory(previewBytes!, fit: BoxFit.cover)
                  else
                    const Center(
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.indigo,
                        size: 56,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: onChooseImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(hasImage ? 'Replace' : 'Choose image'),
            ),
            if (hasImage)
              OutlinedButton.icon(
                onPressed: onRemoveImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}
