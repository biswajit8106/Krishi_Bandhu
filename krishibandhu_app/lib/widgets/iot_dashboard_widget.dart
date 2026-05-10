import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class IotDashboardWidget extends StatefulWidget {
  final String token;
  const IotDashboardWidget({super.key, required this.token});

  @override
  State<IotDashboardWidget> createState() => _IotDashboardWidgetState();
}

class _IotDashboardWidgetState extends State<IotDashboardWidget>
    with TickerProviderStateMixin {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>> _iotDataFuture;
  late Future<Map<String, dynamic>> _irrigationPredictionFuture;
  late AnimationController _animationController;
  late Timer _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _refreshData();
    
    // Auto-refresh every 10 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoRefreshTimer.cancel();
    super.dispose();
  }

  void _refreshData() {
    // Refresh data without rebuilding the page
    // FutureBuilder will automatically update when the futures complete
    _iotDataFuture = api.getIotRealtimeData(widget.token);
    _irrigationPredictionFuture = api.getAiIrrigationPrediction(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refreshData(),
      backgroundColor: Colors.white,
      color: const Color(0xFF2D8659),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            FutureBuilder<Map<String, dynamic>>(
              future: _iotDataFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final lastUpdate = snapshot.data!['last_update'] ?? 'N/A';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farm Monitoring',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1a472a),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-Time IoT Sensor Data',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D8659).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D8659),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Live • Updated now',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D8659),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Sensor Gauges Section
            FutureBuilder<Map<String, dynamic>>(
              future: _iotDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF2D8659),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      '⚠️ Unable to fetch IoT data',
                      style: GoogleFonts.poppins(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                final sensors = data['sensors'] ?? {};

                return ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
                  ),
                  child: Column(
                    children: [
                      // Sensor Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.15,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildEnhancedSensorCard(
                            'Soil Moisture',
                            '${sensors['soil_moisture']?.toStringAsFixed(1) ?? 'N/A'}%',
                            Icons.opacity,
                            Color(0xFF1E88E5),
                            sensors['soil_moisture_status'] ?? 'Normal',
                          ),
                          _buildEnhancedSensorCard(
                            'Temperature',
                            '${sensors['temperature']?.toStringAsFixed(1) ?? 'N/A'}°C',
                            Icons.thermostat,
                            Color(0xFFFF6D00),
                            sensors['temperature_status'] ?? 'Normal',
                          ),
                          _buildEnhancedSensorCard(
                            'Humidity',
                            '${sensors['humidity']?.toStringAsFixed(1) ?? 'N/A'}%',
                            Icons.water_drop,
                            Color(0xFF00BCD4),
                            sensors['humidity_status'] ?? 'Normal',
                          ),
                          _buildEnhancedSensorCard(
                            'Light Intensity',
                            '${sensors['light']?.toStringAsFixed(0) ?? 'N/A'} lx',
                            Icons.light_mode,
                            Color(0xFFFDD835),
                            sensors['light_status'] ?? 'Normal',
                          ),
                          _buildEnhancedSensorCard(
                            'Rain Detection',
                            sensors['rain_detected'] == true ? 'Yes ☔' : 'No',
                            Icons.cloud_queue,
                            sensors['rain_detected'] == true
                                ? Color(0xFF3F51B5)
                                : Color(0xFF9E9E9E),
                            sensors['rain_status'] ?? 'No Rain',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // AI Irrigation Prediction Card
            FutureBuilder<Map<String, dynamic>>(
              future: _irrigationPredictionFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFF2D8659),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final prediction = snapshot.data!;
                final recommendation = prediction['recommendation'] ?? 'No data';
                final urgency = prediction['urgency'] ?? 'normal';
                final reason = prediction['reason'] ?? '';

                return _buildEnhancedPredictionCard(
                  recommendation,
                  urgency,
                  reason,
                );
              },
            ),
            const SizedBox(height: 24),

            // Health Status Card
            _buildEnhancedHealthCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSensorCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String status,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPredictionCard(
    String recommendation,
    String urgency,
    String reason,
  ) {
    final urgencyColor = urgency == 'high'
        ? Color(0xFFD32F2F)
        : urgency == 'medium'
            ? Color(0xFFF57C00)
            : Color(0xFF388E3C);

    final urgencyIcon = urgency == 'high'
        ? '🚨'
        : urgency == 'medium'
            ? '⚠️'
            : '✅';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            urgencyColor.withOpacity(0.12),
            urgencyColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: urgencyColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb, color: urgencyColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Irrigation Insight',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: urgencyColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              '$urgencyIcon ${urgency == 'high' ? 'Urgent Action' : urgency == 'medium' ? 'Medium Priority' : 'All Good'}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: urgencyColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Recommendation',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recommendation,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
              height: 1.5,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedHealthCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D8659).withOpacity(0.08),
            const Color(0xFF2D8659).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF2D8659).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D8659).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFF2D8659),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Farm Health Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHealthIndicatorEnhanced('Soil Quality', 0.75, Color(0xFF4CAF50)),
          const SizedBox(height: 14),
          _buildHealthIndicatorEnhanced(
            'Water Availability',
            0.60,
            Color(0xFF2196F3),
          ),
          const SizedBox(height: 14),
          _buildHealthIndicatorEnhanced(
            'Environmental Conditions',
            0.85,
            Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicatorEnhanced(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(value * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
