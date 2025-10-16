import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WeatherForecastCard extends StatelessWidget {
  final String day;
  final String date;
  final double highTemp;
  final double lowTemp;
  final String condition;
  final int precipitation;

  const WeatherForecastCard({
    super.key,
    required this.day,
    required this.date,
    required this.highTemp,
    required this.lowTemp,
    required this.condition,
    required this.precipitation,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getWeatherIcon(condition),
                    color: _getWeatherColor(condition),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    condition,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${highTemp}°',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        '${lowTemp}°',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  if (precipitation > 0)
                    Column(
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: AppTheme.infoColor,
                          size: 16,
                        ),
                        Text(
                          '$precipitation%',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.infoColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'partly cloudy':
        return Icons.wb_cloudy;
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return AppTheme.warningColor;
      case 'partly cloudy':
        return Colors.grey;
      case 'cloudy':
        return Colors.grey[600]!;
      case 'rainy':
        return AppTheme.infoColor;
      case 'thunderstorm':
        return AppTheme.errorColor;
      default:
        return AppTheme.warningColor;
    }
  }
}
