import 'package:flutter/material.dart';
import 'package:pulso/core/widgets/widgets.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppTextField(
            label: 'Caption',
            hint: 'Share something with the community',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.image_outlined),
            label: const Text('Choose image'),
          ),
          const SizedBox(height: 16),
          CustomButton(label: 'Post', onPressed: () {}),
        ],
      ),
    );
  }
}
