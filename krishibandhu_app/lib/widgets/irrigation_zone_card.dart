import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class IrrigationZoneCard extends StatelessWidget {
  final String zoneName;
  final int moistureLevel;
  final bool isActive;
  final String lastWatered;
  final Function(bool) onToggle;

  const IrrigationZoneCard({
    super.key,
    required this.zoneName,
    required this.moistureLevel,
    required this.isActive,
    required this.lastWatered,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor(moistureLevel);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    zoneName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: onToggle,
                  activeColor: AppTheme.successColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soil Moisture',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$moistureLevel%',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Watered',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastWatered,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: moistureLevel / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getMoistureStatus(moistureLevel),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        // Start irrigation for this zone
                      },
                      color: AppTheme.successColor,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        // Open zone settings
                      },
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(int moistureLevel) {
    if (moistureLevel < 30) {
      return AppTheme.errorColor;
    } else if (moistureLevel < 60) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.successColor;
    }
  }

  String _getMoistureStatus(int moistureLevel) {
    if (moistureLevel < 30) {
      return 'Very Dry - Needs Water';
    } else if (moistureLevel < 60) {
      return 'Dry - Consider Watering';
    } else if (moistureLevel < 80) {
      return 'Optimal';
    } else {
      return 'Wet - Reduce Watering';
    }
  }
}
