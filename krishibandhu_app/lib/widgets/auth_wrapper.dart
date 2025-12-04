import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../krishi_screens/home_screen.dart';
import '../services/api_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refresh_token');
    if (token != null && refreshToken != null) {
      // Try to refresh token
      final result = await ApiService().refreshToken(refreshToken);
      if (result["success"]) {
        final newToken = result["data"]["access_token"];
        final newRefreshToken = result["data"]["refresh_token"];
        await prefs.setString('token', newToken);
        await prefs.setString('refresh_token', newRefreshToken);
        setState(() {
          _token = newToken;
          _isLoading = false;
        });
      } else {
        // Refresh failed, clear tokens
        await prefs.remove('token');
        await prefs.remove('refresh_token');
        setState(() {
          _token = null;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _token = token;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_token != null) {
      return HomeScreen(token: _token!);
    } else {
      return const LoginScreen();
    }
  }
}
