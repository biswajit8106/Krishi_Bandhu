import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_forecast_card.dart';
import '../widgets/weather_chart.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLocation = 'Farm Location';
  String _selectedUnit = 'Celsius';

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
        title: const Text('Weather Prediction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _showLocationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: '7-Day'),
            Tab(text: 'Charts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentWeather(),
          _buildForecastWeather(),
          _buildWeatherCharts(),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationHeader(),
          const SizedBox(height: 24),
          _buildCurrentWeatherCard(),
          const SizedBox(height: 24),
          _buildWeatherDetails(),
          const SizedBox(height: 24),
          _buildWeatherAlerts(),
          const SizedBox(height: 24),
          _buildFarmingRecommendations(),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.infoColor.withOpacity(0.1), AppTheme.primaryColor.withOpacity(0.1)],
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
                  _selectedLocation,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated 5 minutes ago',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '28°C',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.infoColor,
                ),
              ),
              Text(
                'Sunny',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMetric('Humidity', '65%', Icons.water_drop, AppTheme.infoColor),
                _buildWeatherMetric('Wind Speed', '12 km/h', Icons.air, AppTheme.warningColor),
                _buildWeatherMetric('Pressure', '1013 hPa', Icons.compress, AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMetric('UV Index', '6', Icons.wb_sunny, AppTheme.warningColor),
                _buildWeatherMetric('Visibility', '10 km', Icons.visibility, AppTheme.successColor),
                _buildWeatherMetric('Dew Point', '18°C', Icons.water, AppTheme.infoColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(String label, String value, IconData icon, Color color) {
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

  Widget _buildWeatherDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Information',
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
                _buildDetailRow('Feels Like', '30°C'),
                const Divider(),
                _buildDetailRow('Sunrise', '6:15 AM'),
                const Divider(),
                _buildDetailRow('Sunset', '6:45 PM'),
                const Divider(),
                _buildDetailRow('Moon Phase', 'Waxing Crescent'),
                const Divider(),
                _buildDetailRow('Air Quality', 'Good (AQI: 45)'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather Alerts',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppTheme.warningColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warningColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rain Expected Tomorrow',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      Text(
                        'Heavy rainfall expected from 2 PM to 6 PM',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFarmingRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farming Recommendations',
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
                _buildRecommendationItem(
                  'Ideal for irrigation',
                  'Current humidity levels are optimal for watering crops',
                  Icons.water_drop,
                  AppTheme.infoColor,
                ),
                const Divider(),
                _buildRecommendationItem(
                  'Good for spraying',
                  'Low wind conditions are perfect for pesticide application',
                  Icons.pest_control,
                  AppTheme.successColor,
                ),
                const Divider(),
                _buildRecommendationItem(
                  'Monitor soil moisture',
                  'Check soil moisture levels before next irrigation',
                  Icons.eco,
                  AppTheme.warningColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon, Color color) {
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
                  description,
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

  Widget _buildForecastWeather() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (index) => WeatherForecastCard(
            day: _getDayName(index),
            date: _getDate(index),
            highTemp: 28 + (index % 3),
            lowTemp: 18 + (index % 2),
            condition: _getWeatherCondition(index),
            precipitation: (index % 4) * 20,
          )),
        ],
      ),
    );
  }

  Widget _buildWeatherCharts() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature Trends',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          const WeatherChart(),
          const SizedBox(height: 24),
          Text(
            'Precipitation Forecast',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: Text('Precipitation Chart Placeholder'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int index) {
    final days = ['Today', 'Tomorrow', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }

  String _getDate(int index) {
    final now = DateTime.now();
    final date = now.add(Duration(days: index));
    return '${date.day}/${date.month}';
  }

  String _getWeatherCondition(int index) {
    final conditions = ['Sunny', 'Partly Cloudy', 'Cloudy', 'Rainy', 'Thunderstorm'];
    return conditions[index % conditions.length];
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Location', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Farm Location'),
              leading: const Icon(Icons.location_on),
              onTap: () {
                setState(() {
                  _selectedLocation = 'Farm Location';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Field A'),
              leading: const Icon(Icons.agriculture),
              onTap: () {
                setState(() {
                  _selectedLocation = 'Field A';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Field B'),
              leading: const Icon(Icons.agriculture),
              onTap: () {
                setState(() {
                  _selectedLocation = 'Field B';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Weather Settings', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Temperature Unit'),
              subtitle: Text(_selectedUnit),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                setState(() {
                  _selectedUnit = _selectedUnit == 'Celsius' ? 'Fahrenheit' : 'Celsius';
                });
                Navigator.pop(context);
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
