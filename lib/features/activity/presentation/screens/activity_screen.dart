import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.thumb_up_alt_outlined),
            title: Text('Thumbs-up reactions and realtime updates'),
            subtitle: Text('Connect reaction events and live counts here.'),
          ),
          ListTile(
            leading: Icon(Icons.mode_comment_outlined),
            title: Text('Comments'),
            subtitle: Text(
              'Surface comment notifications and realtime threads here.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_add_alt_1_outlined),
            title: Text('Follows'),
            subtitle: Text(
              'Follower activity and follow state can connect here.',
            ),
          ),
        ],
      ),
    );
  }
}
