import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pulso/core/routing/app_routes.dart';
import 'package:pulso/core/theme/app_theme.dart';
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
  final _picker = ImagePicker();
  late final FeedRepository _repository;

  XFile? _pickedImage;
  CroppedFile? _croppedImage;
  Uint8List? _previewBytes;
  bool _isCropping = false;
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

  Future<void> _chooseImage() async {
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
      _croppedImage = null;
      _previewBytes = previewBytes;
    });

    await _cropImage();
  }

  Future<void> _cropImage() async {
    final sourceImage = _pickedImage;
    if (sourceImage == null || _isCropping) {
      return;
    }

    setState(() {
      _isCropping = true;
    });

    try {
      final cropperSide = _cropperSizeFor(context);
      final croppedImage = await ImageCropper().cropImage(
        sourcePath: sourceImage.path,
        maxWidth: 1440,
        maxHeight: 1440,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 92,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Photo',
            toolbarColor: AppTheme.midnight,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Adjust Photo',
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.page,
            size: CropperSize(width: cropperSide, height: cropperSide),
          ),
        ],
      );

      if (croppedImage == null) {
        return;
      }

      final previewBytes = await croppedImage.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _croppedImage = croppedImage;
        _previewBytes = previewBytes;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not crop image: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCropping = false;
        });
      }
    }
  }

  int _cropperSizeFor(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final availableWidth = screenSize.width - 48;
    final availableHeight = screenSize.height - 180;
    final side = math.min(availableWidth, availableHeight);

    return side.clamp(260.0, 420.0).round();
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _croppedImage = null;
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
      await _repository.createPost(caption: _captionController.text);
      if (!mounted) {
        return;
      }

      final message = _previewBytes == null
          ? 'Post published to the community feed.'
          : 'Post published. Image preview is saved locally while upload support is being finished.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
    final hasSelectedImage = _pickedImage != null;

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
              'Caption posts are live now. Image selection and cropping are ready while upload wiring is being finished.',
              style: TextStyle(color: Color(0xFF667085), height: 1.4),
            ),
            const SizedBox(height: 20),
            _ImageComposer(
              previewBytes: _previewBytes,
              canCrop: hasSelectedImage,
              isCropping: _isCropping,
              onChooseImage: _chooseImage,
              onCropImage: _cropImage,
              onRemoveImage: _removeImage,
            ),
            if (_croppedImage != null || _previewBytes != null) ...[
              const SizedBox(height: 12),
              const InlineMessage(
                message:
                    'Image preview is ready. Publishing still sends the caption while full image upload is being connected.',
              ),
            ],
            const SizedBox(height: 16),
            AppTextField(
              controller: _captionController,
              label: 'Caption',
              hint: 'Share something with the community',
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
  final bool canCrop;
  final bool isCropping;
  final VoidCallback onChooseImage;
  final VoidCallback onCropImage;
  final VoidCallback onRemoveImage;

  const _ImageComposer({
    required this.previewBytes,
    required this.canCrop,
    required this.isCropping,
    required this.onChooseImage,
    required this.onCropImage,
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
                  if (isCropping)
                    ColoredBox(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
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
              onPressed: isCropping ? null : onChooseImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(hasImage ? 'Replace' : 'Choose image'),
            ),
            if (canCrop)
              OutlinedButton.icon(
                onPressed: isCropping ? null : onCropImage,
                icon: const Icon(Icons.crop),
                label: const Text('Crop'),
              ),
            if (hasImage)
              OutlinedButton.icon(
                onPressed: isCropping ? null : onRemoveImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }
}

