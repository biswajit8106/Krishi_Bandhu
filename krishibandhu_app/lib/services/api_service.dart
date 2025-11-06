// lib/services/api_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define the backend base URL
// const String baseUrl = "http://10.0.2.2:8000"; // For Android emulator
const String baseUrl = "http://10.107.93.103:9999"; // For Web/PC and mobile devices on same network
// const String localBaseUrl = "https://10.15.83.103:9999"; // For accessing local server over HTTPS
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
  Future<Map<String, dynamic>> predictDisease(String token, String crop, String imageBase64) async {
    final url = Uri.parse("$baseUrl/disease/predict");
    try {
      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Authorization": "Bearer $token",
        },
        body: {
          "crop": crop,
          "image": imageBase64,
        },
      ).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": "An error occurred: ${e.toString()}"};
    }
  }

  // Get Available Crops
  Future<Map<String, dynamic>> getAvailableCrops() async {
    try {
      final url = Uri.parse("$baseUrl/disease/crops");
      final response = await client.get(url).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
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

      final decoded = jsonDecode(response.body);
      // Normalize responses: if backend returns non-200 (e.g. authentication error)
      // convert to a {success: false, msg: ...} shape so UI can handle it safely.
      if (response.statusCode == 200) {
        return decoded;
      } else {
        return {
          "success": false,
          "msg": decoded["detail"] ?? decoded["msg"] ?? "Failed to fetch weather (status ${response.statusCode})"
        };
      }
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

  // Irrigation Prediction
  Future<Map<String, dynamic>> predictIrrigation(String token, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse("$baseUrl/predict_irrigation");
      final response = await client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      ).timeout(_timeoutDuration);

      // Try decode
      final decoded = jsonDecode(response.body);
      return decoded;
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": "An error occurred: ${e.toString()}"};
    }
  }

  // Fetch irrigation metadata (crop types, soil types)
  Future<Map<String, dynamic>> getIrrigationMetadata() async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/metadata");
      final response = await client.get(url).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getIrrigationSchedules(String token) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/schedules");
      final response = await client.get(url, headers: {"Authorization": "Bearer $token"}).timeout(_timeoutDuration);
      return {"success": true, "data": jsonDecode(response.body)};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> createIrrigationSchedule(String token, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/schedules");
      final response = await client.post(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode(body)).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRecentIrrigationEvents(String token) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/events");
      final response = await client.get(url, headers: {"Authorization": "Bearer $token"}).timeout(_timeoutDuration);
      return {"success": true, "data": jsonDecode(response.body)};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> createIrrigationEvent(String token, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/events");
      final response = await client.post(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode(body)).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWaterUsage(String token, {int days = 7}) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/water_usage?days=$days");
      final response = await client.get(url, headers: {"Authorization": "Bearer $token"}).timeout(_timeoutDuration);
      return {"success": true, "data": jsonDecode(response.body)};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> generateAISchedule(String token, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/generate_schedule_ai");
      final response = await client.post(url, headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"}, body: jsonEncode(body)).timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }
}
