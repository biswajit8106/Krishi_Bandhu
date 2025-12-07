import 'package:flutter/material.dart';

class FeedbackPage extends StatelessWidget {
  final String token;
  const FeedbackPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Feedback')),
      body: const Center(child: Text('Feedback page')),
    );
  }
}
