import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color.fromARGB(255, 158, 158, 158),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Section
          _buildSectionTitle('General'),
          _buildSectionCard([
            _buildSelectOption(
              'Select your KrishiBandhu language',
              selectedLanguage,
              [
                'English',
                'Hindi',
                'Bhojpuri',
                'Marathi',
                'Bengali',
                'Odia',
                'Gujarati',
                'Punjabi',
                'Kannada',
                'Tamil',
                'Telugu',
                'Spanish',
                'French',
              ],
              (value) {
                setState(() => selectedLanguage = value);
              },
            ),
            const Divider(height: 1),
            _buildSelectOption(
              'Select your Country',
              selectedCountry,
              ['India'],
              (value) {
                setState(() => selectedCountry = value);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionTitle('Notifications'),
          _buildSectionCard([
            _buildToggleOption(
              'Allow notifications',
              'Receive notifications from KrishiBandhu App',
              notificationsEnabled,
              (value) {
                setState(() => notificationsEnabled = value);
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Weather Section
          _buildSectionTitle('Weather'),
          _buildSectionCard([
            _buildSelectOption(
              'Weather temperature units',
              selectedTemperatureUnit,
              ['Celsius', 'Fahrenheit'],
              (value) {
                setState(() => selectedTemperatureUnit = value);
              },
              description:
                  'Choose your preferred weather temperature unit. Current is $selectedTemperatureUnit',
            ),
          ]),
          const SizedBox(height: 24),

          // Other Section
          _buildSectionTitle('Other'),
          _buildSectionCard([
            _buildToggleOption(
              'Analytics',
              'Help us improve the app by sending anonymous usage data',
              analyticsEnabled,
              (value) {
                setState(() => analyticsEnabled = value);
              },
            ),
            const Divider(height: 1),
            _buildTapOption(
              'Open source licences',
              'List of the used open source licences',
              () {
                // Handle tap
              },
            ),
          ]),
          const SizedBox(height: 24),

          // Application Info
          _buildSectionTitle('Application'),
          _buildSectionCard([
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'About KrishiBandhu App',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'App Version: 1.0.0',
                    style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 168, 168, 168)),
                  ),
                ],
              ),
            ),
          ]),
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

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSelectOption(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged, {
    String? description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<String>(
              value: options.contains(currentValue)
                  ? currentValue
                  : options.first,
              isExpanded: true,
              underline: const SizedBox(),
              items: options
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: const Color.fromARGB(255, 105, 105, 105)),
        ],
      ),
    );
  }

  Widget _buildTapOption(String title, String description, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
