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
    // Zones are no longer used in the UI. Keep the widget as a no-op placeholder
    // to avoid breaking imports elsewhere in the codebase.
    return const SizedBox.shrink();
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
