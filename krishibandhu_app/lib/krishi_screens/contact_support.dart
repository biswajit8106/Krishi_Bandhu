import 'package:flutter/material.dart';

class ContactSupportPage extends StatelessWidget {
  final String token;
  const ContactSupportPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact & Support')),
      body: const Center(child: Text('Contact & Support page')),
    );
  }
}
