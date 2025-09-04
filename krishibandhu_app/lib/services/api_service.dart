import 'dart:convert';
import 'package:http/http.dart' as http;

// Define the backend base URL
// const String baseUrl = "http://10.0.2.2:8000"; // For Android emulator
const String baseUrl = "http://127.0.0.1:8000"; // For Web/PC

class ApiService {
  // Signup
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/signup");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
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
  }
}
