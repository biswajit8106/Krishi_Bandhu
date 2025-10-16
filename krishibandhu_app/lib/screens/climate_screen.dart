import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key});

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? weatherData;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  void fetchWeather() async {
    setState(() => loading = true);
    // Get token from shared preferences or wherever it's stored
    // For now, assuming token is passed or retrieved
    // You might need to adjust this based on how auth is handled in your app
    String? token = await _getToken();
    if (token == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first"), backgroundColor: Colors.red),
      );
      return;
    }
    final result = await apiService.predictClimate(token);
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

  Future<String?> _getToken() async {
    // Implement token retrieval logic
    // This depends on how you store the token in your app
    // For example, using shared_preferences
    // return await SharedPreferences.getInstance().then((prefs) => prefs.getString('token'));
    return null; // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Climate Prediction")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
