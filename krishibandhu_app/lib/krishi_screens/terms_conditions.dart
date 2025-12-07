import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  final String token;
  const TermsConditionsPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Terms and conditions content goes here.'),
      ),
    );
  }
}
