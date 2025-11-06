import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/quick_stats_card.dart';
import '../services/api_service.dart';
import 'crop_disease_screen.dart';
import 'weather_screen.dart';
import 'irrigation_screen.dart';
import 'assistant_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  const HomeScreen({super.key, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchWeather();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final profile = await apiService.getProfile(widget.token);
      setState(() {
        userProfile = profile;
      });
      // Fetch weather for user's state if available
      if (profile['state'] != null) {
        _fetchWeatherForState(profile['state']);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final data = await apiService.predictClimate(widget.token);
      setState(() {
        weatherData = data;
      });
    } catch (e) {
      setState(() {
        weatherData = {"msg": "Failed to fetch weather: $e"};
      });
    }
  }

  Future<void> _fetchWeatherForState(String state) async {
    // Since we now use user's location, no need for state-specific fetch
    // The API will use the user's registered location
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              _buildWeatherSection()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideX(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              _buildQuickStats()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _buildFeaturesSection(context)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideX(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _buildRecentActivity()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 800.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to KrishiBandhu',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Agriculture Solutions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Farm Status: Active',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.agriculture,
            size: 60,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Weather',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        const WeatherCard(),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickStatsCard(
                title: 'Crop Health',
                value: '85%',
                icon: Icons.eco,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickStatsCard(
                title: 'Soil Moisture',
                value: '72%',
                icon: Icons.water_drop,
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickStatsCard(
                title: 'Irrigation',
                value: 'Active',
                icon: Icons.water_drop,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickStatsCard(
                title: 'Yield Prediction',
                value: '2.5T',
                icon: Icons.trending_up,
                color: AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Features',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            FeatureCard(
              title: 'Crop Disease Detection',
              icon: Icons.eco,
              color: AppTheme.errorColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CropDiseaseScreen(token: widget.token)),
                );
              },
            ),
            FeatureCard(
              title: 'Weather Prediction',
              icon: Icons.wb_sunny,
              color: AppTheme.warningColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeatherScreen(token: widget.token)),
                );
              },
            ),
            FeatureCard(
              title: 'Smart Irrigation',
              icon: Icons.water_drop,
              color: AppTheme.infoColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IrrigationScreen(token: widget.token)),
                );
              },
            ),
            FeatureCard(
              title: 'Virtual Assistant',
              icon: Icons.smart_toy,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssistantScreen(token: widget.token)),
                );
              },
            ),
          ],
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
            fontSize: 20,
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
                  icon: Icons.eco,
                  title: 'Crop scan completed',
                  subtitle: 'Rice field - No diseases detected',
                  time: '2 hours ago',
                  color: AppTheme.successColor,
                ),
                const Divider(),
                _buildActivityItem(
                  icon: Icons.water_drop,
                  title: 'Irrigation scheduled',
                  subtitle: 'Field A - 30 minutes',
                  time: '4 hours ago',
                  color: AppTheme.infoColor,
                ),
                const Divider(),
                _buildActivityItem(
                  icon: Icons.wb_sunny,
                  title: 'Weather alert',
                  subtitle: 'Rain expected tomorrow',
                  time: '6 hours ago',
                  color: AppTheme.warningColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
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
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey[600],
      currentIndex: 0, // Home is selected by default
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.eco),
          label: 'Disease',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.wb_sunny),
          label: 'Weather',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.water_drop),
          label: 'Irrigation',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on home
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CropDiseaseScreen(token: widget.token)),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WeatherScreen(token: widget.token)),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => IrrigationScreen(token: widget.token)),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(token: widget.token)),
            );
            break;
        }
      },
    );
  }
}
