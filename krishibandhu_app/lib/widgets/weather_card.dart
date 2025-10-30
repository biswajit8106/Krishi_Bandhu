import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? weatherData;
  bool loading = true;
  bool unauthenticated = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      // Get token from shared preferences or wherever it's stored
      String? token = await _getToken();
      if (token == null) {
        // No token: mark unauthenticated so UI can show a login CTA
        setState(() {
          unauthenticated = true;
          loading = false;
        });
        return;
      }

      final data = await apiService.predictClimate(token);
      setState(() {
        weatherData = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (unauthenticated) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Log in to view weather',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                    );
                  },
                  child: const Text('Log in'),
                ),
              )
            ],
          ),
        ),
      );
    }
    // Treat several shapes from the backend as an error:
    // - null response
    // - explicit "msg" key (our older error shape)
    // - "detail" key (FastAPI auth error)
    // - { success: false, msg: ... }
    final bool hasError = weatherData == null ||
        weatherData!.containsKey('msg') ||
        weatherData!.containsKey('detail') ||
        (weatherData!.containsKey('success') && weatherData!['success'] == false);

    if (hasError) {
      final String message = weatherData == null
          ? 'Weather data unavailable'
          : (weatherData!['msg'] ?? weatherData!['detail'] ?? 'Weather data unavailable');

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny,
                        color: AppTheme.warningColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        weatherData!['condition'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${weatherData?['temperature'] ?? '--'}°C',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: ${weatherData?['city'] ?? '--'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _buildWeatherDetail('Humidity', '${weatherData?['humidity'] ?? '--'}%', Icons.water_drop),
                const SizedBox(height: 12),
                _buildWeatherDetail('Prediction', weatherData?['prediction'] ?? 'Unknown', Icons.wb_cloudy),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
