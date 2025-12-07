import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  final String token;
  const AboutPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('About KrishiBandhu')),
    );
  }
}
