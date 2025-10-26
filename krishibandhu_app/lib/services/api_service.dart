// lib/services/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define the backend base URL
// const String baseUrl = "http://10.0.2.2:8000"; // For Android emulator
const String baseUrl = "http://10.15.83.103:9999"; // For Web/PC and mobile devices on same network
// const String baseUrl = "http://localhost:9999"; // For devices connected via USB with adb reverse

class ApiService {
  final http.Client client = http.Client();
  final Duration _timeoutDuration = const Duration(seconds: 10);

  // Signup
  Future<Map<String, dynamic>> signup({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String state,
    required String district,
    required String location,
    required String language,
  }) async {
    final url = Uri.parse("$baseUrl/auth/signup");
    try {
      final response = await http.post(
        url, 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "phone": phone,
          "email": email,
          "password": password,
          "state": state,
          "district": district,
          "location": location,
          "language": language,
        }),
      ).timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "msg": data["detail"] ?? "Signup failed"};
      }
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"identifier": identifier, "password": password}),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "msg": jsonDecode(response.body)["detail"] ?? "Login failed"};
      }
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Crop Disease Prediction
  Future<Map<String, dynamic>> predictDisease(String token, String imageBase64) async {
    final url = Uri.parse("$baseUrl/disease/predict");
    try {
      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"image": imageBase64}),
      ).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": "An error occurred: ${e.toString()}"};
    }
  }

  // Climate Prediction
  Future<Map<String, dynamic>> predictClimate(String token) async {
    try {
      final url = Uri.parse("$baseUrl/climate/predict");
      final response = await client.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      ).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": "Failed to fetch weather: ${e.toString()}"};
    }
  }

  // Fetch Profile
  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final url = Uri.parse("$baseUrl/profile/me");
      final response = await client.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      ).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": "An error occurred: ${e.toString()}"};
    }
  }
}
