import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class IrrigationScheduleCard extends StatelessWidget {
  final String time;
  final String duration;
  final bool isEnabled;
  final Function(bool) onToggle;

  const IrrigationScheduleCard({
    super.key,
    required this.time,
    required this.duration,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        duration,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: AppTheme.successColor,
                ),
              ],
            ),
            // Zones removed — schedule applies to whole field/irrigation system.
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.schedule : Icons.schedule_outlined,
                  size: 16,
                  color: isEnabled ? AppTheme.successColor : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isEnabled ? 'Active Schedule' : 'Disabled',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isEnabled ? AppTheme.successColor : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Edit schedule
                  },
                  color: Colors.grey[600],
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // Delete schedule
                  },
                  color: AppTheme.errorColor,
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
