import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String token;
  const ProfileScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Center(child: Text("Profile details will come here")),
    );
  }
}
