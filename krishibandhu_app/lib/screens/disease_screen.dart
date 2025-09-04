import 'package:flutter/material.dart';

class DiseaseScreen extends StatelessWidget {
  final String token;
  const DiseaseScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crop Disease Detection")),
      body: Center(child: Text("Disease detection will come here")),
    );
  }
}
