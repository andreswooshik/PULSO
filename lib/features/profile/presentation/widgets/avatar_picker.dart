import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Profile-feature specific widget for picking/displaying avatar
class AvatarPicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(File) onImageSelected;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                widget.currentImageUrl != null &&
                    widget.currentImageUrl!.isNotEmpty
                ? NetworkImage(widget.currentImageUrl!)
                : null,
            child:
                widget.currentImageUrl == null ||
                    widget.currentImageUrl!.isEmpty
                ? const Icon(Icons.person, size: 50)
                : null,
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
        widget.onImageSelected(File(image.path));
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
