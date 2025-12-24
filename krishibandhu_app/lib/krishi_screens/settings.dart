import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_tile.dart';

class SettingsPage extends StatefulWidget {
  final String token;
  const SettingsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedLanguage = 'English';
  String selectedCountry = 'India';
  String selectedTemperatureUnit = 'Celsius';
  bool analyticsEnabled = false;
  bool crashReportingEnabled = false;
  bool notificationsEnabled = true;

  // Settings carried over from Profile screen
  String _selectedTheme = 'System';
  bool _locationEnabled = true;
  bool _dataSyncEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('theme') ?? 'System';
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _locationEnabled = prefs.getBool('locationEnabled') ?? true;
      _dataSyncEnabled = prefs.getBool('dataSyncEnabled') ?? true;
      selectedLanguage = prefs.getString('language') ?? selectedLanguage;
      selectedCountry = prefs.getString('country') ?? selectedCountry;
      selectedTemperatureUnit = prefs.getString('temperatureUnit') ?? selectedTemperatureUnit;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 229, 226, 226),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Settings (from Profile)
          _buildSectionTitle('Settings'),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.palette,
                  title: 'Theme',
                  subtitle: _selectedTheme,
                  onTap: _showThemeDialog,
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: notificationsEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() => notificationsEnabled = value);
                      _saveBool('notificationsEnabled', value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  onTap: null,
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.location_on,
                  title: 'Location Services',
                  subtitle: _locationEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() => _locationEnabled = value);
                      _saveBool('locationEnabled', value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  onTap: null,
                ),
                const Divider(height: 1),
                SettingsTile(
                  icon: Icons.sync,
                  title: 'Data Sync',
                  subtitle: _dataSyncEnabled ? 'Enabled' : 'Disabled',
                  trailing: Switch(
                    value: _dataSyncEnabled,
                    onChanged: (value) {
                      setState(() => _dataSyncEnabled = value);
                      _saveBool('dataSyncEnabled', value);
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Application Info
          _buildSectionTitle('Application'),
          Card(
            child: Column(
              children: [
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About KrishiBandhu',
                  subtitle: 'App version 0.0.1',
                  onTap: _showAboutDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 41, 41, 41),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Theme', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'Light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedTheme = value;
                });
                _saveString('theme', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedTheme = value;
                });
                _saveString('theme', value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedTheme = value;
                });
                _saveString('theme', value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'KrishiBandhu',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.agriculture,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text('Smart Agriculture Solutions'),
        const SizedBox(height: 16),
        const Text(
          'KrishiBandhu helps farmers optimize their crop production through AI-powered disease detection, smart irrigation, weather prediction, and virtual assistance.',
        ),
      ],
    );
  }
}
