import 'package:flutter/material.dart';
import 'package:pulso/features/profile/presentation/widgets/profile_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          CircleAvatar(radius: 44, child: Icon(Icons.person, size: 44)),
          SizedBox(height: 16),
          Center(
            child: Text(
              'Community Member',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ProfileStatItem(label: 'Posts', value: '0'),
              ProfileStatItem(label: 'Followers', value: '0'),
              ProfileStatItem(label: 'Following', value: '0'),
            ],
          ),
        ],
      ),
    );
  }
}
