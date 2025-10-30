import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WeatherInfoCard extends StatelessWidget {
  final Map<String, dynamic>? weatherData;

  const WeatherInfoCard({super.key, this.weatherData});

  @override
  Widget build(BuildContext context) {
    if (weatherData == null || weatherData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final temperature = weatherData!['temperature'] ?? '--';
    final condition = weatherData!['condition'] ?? 'Unknown';
    final humidity = weatherData!['humidity'] ?? '--';
    final city = weatherData!['city'] ?? '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Weather',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$temperature°C - $condition',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Location: $city',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Humidity: $humidity%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
