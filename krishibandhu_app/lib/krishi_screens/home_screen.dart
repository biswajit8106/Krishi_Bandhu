import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/feature_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/api_service.dart';
import 'crop_disease_screen.dart';
import 'weather_screen.dart';
import 'irrigation_screen.dart';
import 'assistant_screen.dart';
import 'profile_screen.dart';
import 'feedback.dart';
import 'contact_support.dart';
import 'terms_conditions.dart';
import 'about.dart';
import 'settings.dart';

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
  List<dynamic> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchWeather();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    try {
      final res = await apiService.getRecentActivities(widget.token);
      if (res != null && res is Map && res.containsKey('activities')) {
        setState(() {
          _recentActivities = List<dynamic>.from(res['activities'] ?? []);
        });
      }
    } catch (_) {}
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),
              const SizedBox(height: 16),
              _buildHeader(
                context,
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              _buildWeatherSection()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideX(begin: -0.1, end: 0),
              // const SizedBox(height: 24),
              // _buildQuickStats()
              //     .animate()
              //     .fadeIn(duration: 600.ms, delay: 400.ms)
              //     .slideY(begin: 0.1, end: 0),
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

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(token: widget.token),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
        ),
        const Spacer(),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            switch (value) {
              case 'about':
                AboutPage.showAboutDialog(context);
                break;
              case 'settings':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(token: widget.token),
                  ),
                );
                break;
              case 'feedback':
                showFeedbackDialog(context, token: widget.token);
                break;
              case 'contact':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ContactSupportPage(token: widget.token),
                  ),
                );
                break;
              case 'terms':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TermsConditionsPage(token: widget.token),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'about', 
              child: Text('About')
            ),
            const PopupMenuItem(
              value: 'settings', 
              child: Text('Settings')
            ),
            const PopupMenuItem(
              value: 'feedback',
              child: Text('Feedback'),
            ),
            const PopupMenuItem(
              value: 'contact',
              child: Text('Contact & Support'),
            ),
            const PopupMenuItem(
              value: 'terms',
              child: Text('Terms & Conditions'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Agriculture Solutions',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Status: Active',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.agriculture, size: 60, color: Colors.white),
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
              title: 'Disease Detection',
              icon: Icons.eco,
              color: AppTheme.errorColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CropDiseaseScreen(token: widget.token),
                  ),
                );
              },
            ),
            FeatureCard(
              title: 'Weather',
              icon: Icons.wb_sunny,
              color: AppTheme.warningColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherScreen(token: widget.token),
                  ),
                );
              },
            ),
            FeatureCard(
              title: 'Irrigation',
              icon: Icons.water_drop,
              color: AppTheme.infoColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IrrigationScreen(token: widget.token),
                  ),
                );
              },
            ),
            FeatureCard(
              title: 'Assistant',
              icon: Icons.smart_toy,
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssistantScreen(token: widget.token),
                  ),
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
              children: _recentActivities.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No recent activity', style: GoogleFonts.poppins()),
                      )
                    ]
                  : _recentActivities.map((act) {
                      IconData icon = Icons.event;
                      Color color = AppTheme.infoColor;
                      String title = act['title'] ?? '';
                      String subtitle = act['details'] ?? '';
                      String time = act['timestamp'] ?? '';

                      switch (act['type']) {
                        case 'irrigation':
                          icon = Icons.water_drop;
                          color = AppTheme.infoColor;
                          break;
                        case 'assistant':
                          icon = Icons.smart_toy;
                          color = AppTheme.primaryColor;
                          break;
                        case 'disease':
                          icon = Icons.eco;
                          color = AppTheme.errorColor;
                          break;
                        default:
                          icon = Icons.event;
                      }

                      return Column(
                        children: [
                          _buildActivityItem(
                            icon: icon,
                            title: title,
                            subtitle: subtitle,
                            time: time,
                            color: color,
                          ),
                          const Divider(),
                        ],
                      );
                    }).toList(),
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
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavBar(currentIndex: 0, token: widget.token);
  }
}
