import 'package:flutter/material.dart';
import 'disease_screen.dart';
import 'climate_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String token;
  const DashboardScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AgroBrain Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DiseaseScreen(token: token))),
              child: const Text("Crop Disease Detection"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => ClimateScreen())),
              child: const Text("Climate Prediction"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfileScreen(token: token))),
              child: const Text("Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
