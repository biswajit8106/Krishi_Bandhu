import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_forecast_card.dart';
import '../widgets/weather_chart.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';

class WeatherScreen extends StatefulWidget {
  final String token;
  const WeatherScreen({super.key, required this.token});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedLocation = 'Farm Location';
  String _selectedUnit = 'Celsius';
  final ApiService apiService = ApiService();
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final data = await apiService.predictClimate(widget.token);
      setState(() {
        weatherData = data;
        // Update the location to show user's registered location
        if (data.containsKey('city')) {
          _selectedLocation = data['city'];
        }
      });
    } catch (e) {
      setState(() {
        weatherData = {"msg": "Failed to fetch weather: $e"};
      });
    }
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
            Tab(text: 'Upcoming Days'),
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
      bottomNavigationBar: BottomNavBar(currentIndex: 2, token: widget.token),
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
    if (weatherData != null && weatherData!.containsKey('msg')) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                weatherData!['msg'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.infoColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
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
                weatherData != null && weatherData!.containsKey('temperature')
                    ? '${weatherData!['temperature']}°C'
                    : '--°C',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.infoColor,
                ),
              ),
              Text(
                weatherData != null && weatherData!.containsKey('condition')
                    ? weatherData!['condition']
                    : 'Sunny',
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
    if (weatherData != null && weatherData!.containsKey('msg')) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMetric(
                  'Humidity',
                  weatherData != null && weatherData!.containsKey('humidity')
                      ? '${weatherData!['humidity']}%'
                      : '--%',
                  Icons.water_drop,
                  AppTheme.infoColor,
                ),
                _buildWeatherMetric(
                  'Wind Speed',
                  weatherData != null && weatherData!.containsKey('wind_speed')
                      ? '${weatherData!['wind_speed']} km/h'
                      : '-- km/h',
                  Icons.air,
                  AppTheme.warningColor,
                ),
                _buildWeatherMetric(
                  'Pressure',
                  weatherData != null && weatherData!.containsKey('pressure')
                      ? '${weatherData!['pressure']} hPa'
                      : '-- hPa',
                  Icons.compress,
                  AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherMetric(
                  'UV Index',
                  weatherData != null && weatherData!.containsKey('uv_index')
                      ? '${weatherData!['uv_index']}'
                      : '--',
                  Icons.wb_sunny,
                  AppTheme.warningColor,
                ),
                _buildWeatherMetric(
                  'Visibility',
                  weatherData != null && weatherData!.containsKey('visibility')
                      ? '${weatherData!['visibility']} km'
                      : '-- km',
                  Icons.visibility,
                  AppTheme.successColor,
                ),
                _buildWeatherMetric(
                  'Dew Point',
                  weatherData != null && weatherData!.containsKey('dew_point')
                      ? '${weatherData!['dew_point']}°C'
                      : '--°C',
                  Icons.water,
                  AppTheme.infoColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildWeatherDetails() {
    if (weatherData != null && weatherData!.containsKey('msg')) {
      return const SizedBox.shrink();
    }

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
                _buildDetailRow(
                  'Feels Like',
                  weatherData != null && weatherData!.containsKey('feels_like')
                      ? '${weatherData!['feels_like']}°C'
                      : '--°C',
                ),
                const Divider(),
                _buildDetailRow(
                  'Sunrise',
                  weatherData != null && weatherData!.containsKey('sunrise')
                      ? weatherData!['sunrise']
                      : '--',
                ),
                const Divider(),
                _buildDetailRow(
                  'Sunset',
                  weatherData != null && weatherData!.containsKey('sunset')
                      ? weatherData!['sunset']
                      : '--',
                ),
                const Divider(),
                _buildDetailRow(
                  'Moon Phase',
                  weatherData != null && weatherData!.containsKey('moon_phase')
                      ? weatherData!['moon_phase']
                      : '--',
                ),
                const Divider(),
                _buildDetailRow(
                  'Air Quality',
                  weatherData != null && weatherData!.containsKey('air_quality')
                      ? weatherData!['air_quality']
                      : '--',
                ),
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
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
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
    if (weatherData == null ||
        !weatherData!.containsKey('alert_title') ||
        weatherData!['alert_title'] == null) {
      return const SizedBox.shrink();
    }

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
                        weatherData!['alert_title'] ?? 'Weather Alert',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      Text(
                        weatherData!['alert_description'] ??
                            'Please check weather conditions',
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
    if (weatherData != null && weatherData!.containsKey('msg')) {
      return const SizedBox.shrink();
    }

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

  Widget _buildRecommendationItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
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
    if (weatherData == null ||
        !weatherData!.containsKey('forecast') ||
        weatherData!['forecast'] == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming-Days Forecast',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('Forecast data not available')),
          ],
        ),
      );
    }

    List<dynamic> forecast = weatherData!['forecast'];

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
          ...forecast.map(
            (day) => WeatherForecastCard(
              day: day['day'] ?? 'Unknown',
              date: day['date'] ?? '--/--',
              highTemp: (day['high_temp'] as num?)?.toDouble() ?? 0.0,
              lowTemp: (day['low_temp'] as num?)?.toDouble() ?? 0.0,
              condition: day['condition'] ?? 'Unknown',
              precipitation: (day['precipitation'] as num?)?.toInt() ?? 0,
            ),
          ),
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
          ]
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
                  _selectedUnit = _selectedUnit == 'Celsius'
                      ? 'Fahrenheit'
                      : 'Celsius';
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
