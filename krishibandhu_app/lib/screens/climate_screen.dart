import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  final ApiService apiService = ApiService();
  String city = "";
  Map<String, dynamic>? weatherData;
  bool loading = false;

  void fetchWeather() async {
    setState(() => loading = true);
    final result = await apiService.predictClimate(city);
    if (result.containsKey("msg")) {
      // Error
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["msg"]), backgroundColor: Colors.red),
      );
    } else {
      // Success
      setState(() {
        loading = false;
        weatherData = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Climate Prediction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Enter City"),
              onChanged: (val) => city = val,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchWeather,
              child: const Text("Get Weather"),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            if (weatherData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("🌍 City: ${weatherData!['city']}"),
                      Text("🌡 Temp: ${weatherData!['temperature']} °C"),
                      Text("💧 Humidity: ${weatherData!['humidity']}%"),
                      Text("☁ Condition: ${weatherData!['condition']}"),
                      Text("🔮 Prediction: ${weatherData!['prediction']}"),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
