import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/irrigation_models.dart';

class IrrigationScheduleCard extends StatelessWidget {
  final String time;
  final String duration;
  final bool isEnabled;
  final Function(bool) onToggle;
  final List<PredictedIrrigationDay>? predictedPlan; // optional day-wise predictions

  const IrrigationScheduleCard({
    super.key,
    required this.time,
    required this.duration,
    required this.isEnabled,
    required this.onToggle,
    this.predictedPlan,
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
            // Day-wise predicted irrigation plan (optional)
            const SizedBox(height: 12),
            if ((predictedPlan ?? []).isNotEmpty) ...[
              Text(
                'Predicted Plan',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: predictedPlan!.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final p = predictedPlan![index];
                    final dayLabel = _weekdayLabel(p.day);
                    final dateLabel = '${p.day.day}/${p.day.month}';
                    return Container(
                      width: 120,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            dateLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.opacity,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${p.durationMinutes} min · ${p.waterLitres.toStringAsFixed(1)} L',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Fallback: small mock preview (next 3 days) for development/demo
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'No predicted plan available. Connect model or pass `predictedPlan` to show day-wise predictions.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _weekdayLabel(DateTime d) {
  switch (d.weekday) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    case DateTime.sunday:
      return 'Sun';
    default:
      return '';
  }
}
