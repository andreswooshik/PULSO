import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/widgets/widgets.dart';
import 'package:pulso/features/feed/data/feed_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  late final FeedRepository _repository;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _repository = FeedRepository(Supabase.instance.client);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
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
      await _repository.createPost(caption: _captionController.text);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published to the community feed.')),
      );
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
              'A caption-only post is enough to start comments and activity. Image uploads can come next.',
              style: TextStyle(color: Color(0xFF667085), height: 1.4),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _captionController,
              label: 'Caption',
              hint: 'Share something with the community',
              maxLines: 5,
              validator: _validateCaption,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Image upload coming soon'),
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
