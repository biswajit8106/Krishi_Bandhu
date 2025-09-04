import 'package:flutter/material.dart';

class ClimateScreen extends StatelessWidget {
  const ClimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Climate Prediction")),
      body: Center(child: Text("Climate prediction will come here")),
    );
  }
}
