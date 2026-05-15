import 'package:flutter/material.dart';

/// Profile-feature specific widget for picking/displaying avatar
class AvatarPicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String) onImageSelected;

  const AvatarPicker({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: widget.currentImageUrl != null
                ? NetworkImage(widget.currentImageUrl!)
                : null,
            child: widget.currentImageUrl == null
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

  void _pickImage() {
    // TODO: Implement image picking using image_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker to be implemented')),
    );
  }
}
