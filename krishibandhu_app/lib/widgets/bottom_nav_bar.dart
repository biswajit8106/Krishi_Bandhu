import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../krishi_screens/home_screen.dart';
import '../krishi_screens/crop_disease_screen.dart';
import '../krishi_screens/weather_screen.dart';
import '../krishi_screens/irrigation_screen.dart';
import '../krishi_screens/assistant_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String token;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey[600],
      currentIndex: currentIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'Disease'),
        BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Weather'),
        BottomNavigationBarItem(icon: Icon(Icons.water_drop),label: 'Irrigation',),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy),label: 'Assistant',),
      ],
      onTap: (index) {
        _navigateToPage(context, index);
      },
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    // Don't navigate if already on the same page
    if (index == currentIndex) {
      return;
    }

    Widget page;
    switch (index) {
      case 0:
        page = HomeScreen(token: token);
        break;
      case 1:
        page = CropDiseaseScreen(token: token);
        break;
      case 2:
        page = WeatherScreen(token: token);
        break;
      case 3:
        page = IrrigationScreen(token: token);
        break;
      case 4:
        page = AssistantScreen(token: token);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
