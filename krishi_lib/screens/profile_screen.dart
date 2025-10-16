import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_stat_card.dart';
import '../widgets/settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedTheme = 'System';
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _dataSyncEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildSettingsSection(),
            const SizedBox(height: 24),
            _buildAccountSection(),
            const SizedBox(height: 24),
            _buildSupportSection(),
            const SizedBox(height: 24),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rajesh Kumar',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'rajesh.kumar@email.com',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Premium Member',
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
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Statistics',
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
              child: ProfileStatCard(
                title: 'Total Fields',
                value: '4',
                icon: Icons.agriculture,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileStatCard(
                title: 'Crop Types',
                value: '3',
                icon: Icons.eco,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ProfileStatCard(
                title: 'Yield (This Year)',
                value: '2.5T',
                icon: Icons.trending_up,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileStatCard(
                title: 'Water Saved',
                value: '15%',
                icon: Icons.water_drop,
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
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
                subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
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
                    setState(() {
                      _locationEnabled = value;
                    });
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
                    setState(() {
                      _dataSyncEnabled = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
                onTap: null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle: 'Update your profile details',
                onTap: () {
                  // Navigate to personal info
                },
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  // Navigate to privacy settings
                },
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () {
                  // Navigate to change password
                },
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.payment,
                title: 'Billing & Subscription',
                subtitle: 'Manage your subscription',
                onTap: () {
                  // Navigate to billing
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help and support',
                onTap: () {
                  // Navigate to help center
                },
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.chat,
                title: 'Contact Support',
                subtitle: 'Chat with our support team',
                onTap: () {
                  // Navigate to support chat
                },
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.feedback,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts',
                onTap: () {
                  // Navigate to feedback
                },
              ),
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'About KrishiBandhu',
                subtitle: 'App version 1.0.0',
                onTap: () {
                  _showAboutDialog();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile', style: GoogleFonts.poppins()),
        content: const Text('Profile editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'Dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('System'),
              value: 'System',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
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
        const Text('KrishiBandhu helps farmers optimize their crop production through AI-powered disease detection, smart irrigation, weather prediction, and virtual assistance.'),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.poppins()),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
