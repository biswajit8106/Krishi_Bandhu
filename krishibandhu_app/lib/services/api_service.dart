// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// Define the backend base URL
// const String baseUrl = "http://10.0.2.2:8000"; // For Android emulator
const String baseUrl = "http://127.0.0.1:8000"; // For Web/PC

class ApiService {
  final http.Client client = http.Client();

  // Signup
  Future<Map<String, dynamic>> signup({
    required String name,
    required String phone,
    String? email,
    required String password,
    required String state,
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
          "language": language,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "msg": data["detail"] ?? "Signup failed"};
      }
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "msg": jsonDecode(response.body)["detail"] ?? "Login failed"};
      }
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Crop Disease Prediction
  Future<Map<String, dynamic>> predictDisease(String token, String imageBase64) async {
    final url = Uri.parse("$baseUrl/disease/predict");
    final response = await client.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"image": imageBase64}),
    );
    return jsonDecode(response.body);
  }

  // Climate Prediction
  Future<Map<String, dynamic>> predictClimate(String city) async {
    try {
      final url = Uri.parse("$baseUrl/climate/predict?city=$city");
      final response = await client.get(url);
      return jsonDecode(response.body);
    } catch (e) {
      return {"msg": "Failed to fetch weather: ${e.toString()}"};
    }
  }

  // Fetch Profile
  Future<Map<String, dynamic>> getProfile(String token) async {
    final url = Uri.parse("$baseUrl/profile/me");
    final response = await client.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(response.body);
  }
}
