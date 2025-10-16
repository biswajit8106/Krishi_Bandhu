import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/irrigation_zone_card.dart';
import '../widgets/soil_moisture_chart.dart';
import '../widgets/irrigation_schedule_card.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isIrrigationActive = false;
  String _selectedMode = 'Auto';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart Irrigation'),
        actions: [
          IconButton(
            icon: Icon(_isIrrigationActive ? Icons.stop : Icons.play_arrow),
            onPressed: _toggleIrrigation,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Zones'),
            Tab(text: 'Schedule'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildZones(),
          _buildSchedule(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIrrigationStatus(),
          const SizedBox(height: 24),
          _buildQuickControls(),
          const SizedBox(height: 24),
          _buildSoilMoistureChart(),
          const SizedBox(height: 24),
          _buildWaterUsageStats(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildIrrigationStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isIrrigationActive 
              ? [AppTheme.successColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.1)]
              : [AppTheme.warningColor.withOpacity(0.1), AppTheme.errorColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Irrigation System',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isIrrigationActive ? 'Currently Active' : 'System Offline',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: _isIrrigationActive ? AppTheme.successColor : AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mode: $_selectedMode',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isIrrigationActive ? AppTheme.successColor : AppTheme.errorColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isIrrigationActive ? Icons.water_drop : Icons.water_drop_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Controls',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildControlButton(
                'Start All Zones',
                Icons.play_arrow,
                AppTheme.successColor,
                () => _startAllZones(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildControlButton(
                'Stop All Zones',
                Icons.stop,
                AppTheme.errorColor,
                () => _stopAllZones(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildControlButton(
                'Emergency Stop',
                Icons.emergency,
                AppTheme.errorColor,
                () => _emergencyStop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildControlButton(
                'Test System',
                Icons.build,
                AppTheme.warningColor,
                () => _testSystem(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSoilMoistureChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Soil Moisture Levels',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        const SoilMoistureChart(),
      ],
    );
  }

  Widget _buildWaterUsageStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Water Usage Statistics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Today', '125 L', Icons.today, AppTheme.infoColor),
                    _buildStatItem('This Week', '875 L', Icons.date_range, AppTheme.primaryColor),
                    _buildStatItem('This Month', '3.2 KL', Icons.calendar_month, AppTheme.warningColor),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Efficiency', '92%', Icons.trending_up, AppTheme.successColor),
                    _buildStatItem('Savings', '15%', Icons.savings, AppTheme.successColor),
                    _buildStatItem('Cost', '\$45', Icons.attach_money, AppTheme.errorColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  'Zone A irrigation completed',
                  '2 hours ago',
                  Icons.water_drop,
                  AppTheme.successColor,
                ),
                const Divider(),
                _buildActivityItem(
                  'Soil moisture sensor calibrated',
                  '4 hours ago',
                  Icons.sensors,
                  AppTheme.infoColor,
                ),
                const Divider(),
                _buildActivityItem(
                  'Water pressure alert resolved',
                  '6 hours ago',
                  Icons.warning,
                  AppTheme.warningColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZones() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Irrigation Zones',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          IrrigationZoneCard(
            zoneName: 'Zone A - Rice Field',
            moistureLevel: 72,
            isActive: true,
            lastWatered: '2 hours ago',
            onToggle: (isActive) {
              // Handle zone toggle
            },
          ),
          const SizedBox(height: 12),
          IrrigationZoneCard(
            zoneName: 'Zone B - Vegetable Garden',
            moistureLevel: 45,
            isActive: false,
            lastWatered: '6 hours ago',
            onToggle: (isActive) {
              // Handle zone toggle
            },
          ),
          const SizedBox(height: 12),
          IrrigationZoneCard(
            zoneName: 'Zone C - Orchard',
            moistureLevel: 68,
            isActive: true,
            lastWatered: '1 hour ago',
            onToggle: (isActive) {
              // Handle zone toggle
            },
          ),
          const SizedBox(height: 12),
          IrrigationZoneCard(
            zoneName: 'Zone D - Greenhouse',
            moistureLevel: 38,
            isActive: false,
            lastWatered: '8 hours ago',
            onToggle: (isActive) {
              // Handle zone toggle
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Irrigation Schedule',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          IrrigationScheduleCard(
            time: '06:00 AM',
            zones: ['Zone A', 'Zone C'],
            duration: '30 minutes',
            isEnabled: true,
            onToggle: (isEnabled) {
              // Handle schedule toggle
            },
          ),
          const SizedBox(height: 12),
          IrrigationScheduleCard(
            time: '02:00 PM',
            zones: ['Zone B', 'Zone D'],
            duration: '20 minutes',
            isEnabled: true,
            onToggle: (isEnabled) {
              // Handle schedule toggle
            },
          ),
          const SizedBox(height: 12),
          IrrigationScheduleCard(
            time: '08:00 PM',
            zones: ['Zone A'],
            duration: '15 minutes',
            isEnabled: false,
            onToggle: (isEnabled) {
              // Handle schedule toggle
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Add new schedule
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleIrrigation() {
    setState(() {
      _isIrrigationActive = !_isIrrigationActive;
    });
  }

  void _startAllZones() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting all irrigation zones...')),
    );
  }

  void _stopAllZones() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stopping all irrigation zones...')),
    );
  }

  void _emergencyStop() {
    setState(() {
      _isIrrigationActive = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency stop activated!')),
    );
  }

  void _testSystem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Running system test...')),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Irrigation Settings', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Mode'),
              subtitle: Text(_selectedMode),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  _selectedMode = _selectedMode == 'Auto' ? 'Manual' : 'Auto';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Water Pressure'),
              subtitle: const Text('2.5 bar'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to pressure settings
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
