import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Profile-feature specific widget for picking/displaying avatar
class AvatarPicker extends StatefulWidget {
  final String? currentImageUrl;
  final ValueChanged<XFile> onImageSelected;

  const AvatarPicker({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final ImagePicker _picker = ImagePicker();

  bool get _hasAvatarUrl =>
      widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            child: _hasAvatarUrl
                ? ClipOval(child: _AvatarImage(source: widget.currentImageUrl!))
                : const Icon(Icons.person, size: 50),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        widget.onImageSelected(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }
}

class _AvatarImage extends StatelessWidget {
  final String source;

  const _AvatarImage({required this.source});

  @override
  Widget build(BuildContext context) {
    if (_isDataUri(source)) {
      final bytes = _decodeImageBytes(source);
      if (bytes != null) {
        return Image.memory(bytes, width: 100, height: 100, fit: BoxFit.cover);
      }
    }

    return Image.network(
      source,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.person, size: 50),
    );
  }

  static bool _isDataUri(String value) => value.startsWith('data:image');

  static Uint8List? _decodeImageBytes(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1) {
      return null;
    }

    final encoded = value.substring(commaIndex + 1);
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
