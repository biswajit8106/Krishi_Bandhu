import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../helpers/language_helper.dart';

// Define the backend base URL
// const String baseUrl = "http://10.0.2.2:8000"; // For Android emulator
const String baseUrl =
    "http://10.167.86.103:9999"; // For Web/PC and mobile devices on same network
// const String localBaseUrl = "https://10.15.83.103:9999"; // For accessing local server over HTTPS
// const String baseUrl = "http://10.164.152.146:9999"; // For local development

class ApiService {
  final http.Client client = http.Client();
  final Duration _timeoutDuration = const Duration(seconds: 15);

  // Helper method to construct full image URL
  String getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    return '$baseUrl$imagePath';
  }

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
      final response = await http
          .post(
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
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "msg": data["detail"] ?? "Signup failed"};
      }
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");
    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"identifier": identifier, "password": password}),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {
          "success": false,
          "msg": jsonDecode(response.body)["detail"] ?? "Login failed",
        };
      }
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Crop Disease Prediction
  Future<Map<String, dynamic>> predictDisease(
    String token,
    String cropType,
    String imageBase64,
  ) async {
    final url = Uri.parse("$baseUrl/disease/predict");
    try {
      final response = await client
          .post(
            url,
            headers: {
              "Content-Type": "application/x-www-form-urlencoded",
              "Authorization": "Bearer $token",
            },
            body: {"crop_type": cropType, "file": imageBase64},
          )
          .timeout(_timeoutDuration);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Normalize backend response keys so UI can rely on consistent fields
        try {
          // Ensure both `prediction` and `predicted_class` are available
          if (data is Map<String, dynamic>) {
            if (data.containsKey('predicted_class') &&
                !data.containsKey('prediction')) {
              data['prediction'] = data['predicted_class'];
            }

            // Guarantee recommendation & prevention exist to avoid null checks in UI
            if (!data.containsKey('recommendation'))
              data['recommendation'] = '';
            if (!data.containsKey('prevention')) data['prevention'] = '';

            // Also support backend returning 'prediction' only but frontend reading 'predicted_class'
            if (data.containsKey('prediction') &&
                !data.containsKey('predicted_class')) {
              data['predicted_class'] = data['prediction'];
            }
          }
        } catch (_) {}

        // Debug log to make it easy to inspect API shape while testing
        try {
          // ignore: avoid_print
          print(
            '[ApiService] predictDisease response keys: ' +
                (data is Map ? data.keys.toString() : data.toString()),
          );
          if (data is Map) {
            // ignore: avoid_print
            print(
              '[ApiService] recommendation: ' +
                  (data['recommendation']?.toString() ?? '<null>'),
            );
            // ignore: avoid_print
            print(
              '[ApiService] prevention: ' +
                  (data['prevention']?.toString() ?? '<null>'),
            );
          }
        } catch (_) {}

        // Return success with normalized data
        return {"success": true, "data": data};
      } else {
        return {"success": false, "msg": data["error"] ?? "Prediction failed"};
      }
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
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

  // Get user's crop disease scan history
  Future<Map<String, dynamic>> getDiseaseHistory(String token) async {
    try {
      final url = Uri.parse("$baseUrl/disease/history");
      final response = await client
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final decoded = jsonDecode(response.body);
        return {"success": false, "msg": decoded["error"] ?? decoded["detail"] ?? "Failed to fetch history"};
      }
    } on TimeoutException {
      return {"success": false, "msg": "Connection timed out. Please check your network."};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Climate Prediction
  Future<Map<String, dynamic>> predictClimate(String token) async {
    try {
      final url = Uri.parse("$baseUrl/climate/predict");
      final response = await client
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(_timeoutDuration);

      final decoded = jsonDecode(response.body);
      // Normalize responses: if backend returns non-200 (e.g. authentication error)
      // convert to a {success: false, msg: ...} shape so UI can handle it safely.
      if (response.statusCode == 200) {
        return decoded;
      } else {
        return {
          "success": false,
          "msg":
              decoded["detail"] ??
              decoded["msg"] ??
              "Failed to fetch weather (status ${response.statusCode})",
        };
      }
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {
        "success": false,
        "msg": "Failed to fetch weather: ${e.toString()}",
      };
    }
  }

  // Fetch Profile
  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final url = Uri.parse("$baseUrl/profile/me");
      final response = await client
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {"success": false, "msg": "An error occurred: ${e.toString()}"};
    }
  }

  // Irrigation Prediction
  Future<Map<String, dynamic>> predictIrrigation(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/predict_irrigation");
      final response = await client
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);

      // Try decode
      final decoded = jsonDecode(response.body);
      return decoded;
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
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
      final response = await client
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(_timeoutDuration);
      return {"success": true, "data": jsonDecode(response.body)};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> createIrrigationSchedule(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/schedules");
      final response = await client
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getRecentIrrigationEvents(String token) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/events");
      final response = await client
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(_timeoutDuration);
      return {"success": true, "data": jsonDecode(response.body)};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> createIrrigationEvent(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/events");
      final response = await client
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWaterUsage(
    String token, {
    int days = 7,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/water_usage?days=$days");
      final response = await client
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(_timeoutDuration);
      return {"success": true, "data": jsonDecode(response.body)};
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  Future<Map<String, dynamic>> generateAISchedule(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = Uri.parse("$baseUrl/irrigation/generate_schedule_ai");
      final response = await client
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Refresh Token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final url = Uri.parse("$baseUrl/auth/refresh");
    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refresh_token": refreshToken}),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {
          "success": false,
          "msg": jsonDecode(response.body)["detail"] ?? "Refresh failed",
        };
      }
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {"success": false, "msg": e.toString()};
    }
  }

  // Get Recent Activities
  Future<Map<String, dynamic>> getRecentActivities(String token) async {
    try {
      final url = Uri.parse("$baseUrl/profile/recent-activities");
      final response = await client
          .get(url, headers: {"Authorization": "Bearer $token"})
          .timeout(_timeoutDuration);
      return jsonDecode(response.body);
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {
        "success": false,
        "msg": "Failed to fetch recent activities: ${e.toString()}",
      };
    }
  }

  // -----------------------------
  // 🔥 LANGUAGE NORMALIZER
  // Converts UI label -> API code
  // -----------------------------
  String _normalizeLang(String langUI) {
    return LanguageHelper.toApiCode(langUI);
  }

  // -----------------------------
  // TEXT ASSISTANT CHAT
  // -----------------------------
  Future<Map<String, dynamic>> assistantChat(
    String token,
    String message,
    String uiLanguage,
  ) async {
    final apiLang = _normalizeLang(uiLanguage);

    try {
      final url = Uri.parse("$baseUrl/assistant/chat");
      final res = await client
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "message": message,
              "language": apiLang, // ← CORRECT CODE
            }),
          )
          .timeout(_timeoutDuration);

      print("DEBUG: API chat response status: ${res.statusCode}");
      print("DEBUG: API chat response body: ${res.body}");
      
      if (res.statusCode != 200) {
        print("DEBUG: API error status code: ${res.statusCode}");
        return {
          "success": false,
          "error": "API Error: Status ${res.statusCode}",
          "response": null,
          "audio_url": null,
        };
      }
      
      final response = jsonDecode(res.body);
      print("DEBUG: Parsed response: $response");
      return response;
    } on TimeoutException {
      return {
        "success": false,
        "error": "Connection timed out.",
        "response": null,
        "audio_url": null,
      };
    } catch (e) {
      print("DEBUG: Chat exception: $e");
      return {
        "success": false,
        "error": "Chat error: $e",
        "response": null,
        "audio_url": null,
      };
    }
  }

  // -----------------------------
  // VOICE ASSISTANT
  // -----------------------------
  Future<Map<String, dynamic>> assistantVoice(
    String token,
    File audioFile,
    String uiLanguage,
  ) async {
    final apiLang = _normalizeLang(uiLanguage);

    try {
      final url = Uri.parse("$baseUrl/assistant/voice");

      final request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";
      request.fields["language"] = apiLang; // ← FIXED
      request.files.add(
        await http.MultipartFile.fromPath("file", audioFile.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      // Convert relative URL → absolute URL
      if (data["audio_url"] != null && data["audio_url"].startsWith("/")) {
        data["audio_url"] = "$baseUrl${data["audio_url"]}";
      }

      return data;
    } on TimeoutException {
      return {"success": false, "msg": "Voice request timed out."};
    } catch (e) {
      return {"success": false, "msg": "Voice error: $e"};
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/auth/change-password");
    try {
      final response = await client
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "old_password": oldPassword,
              "new_password": newPassword,
            }),
          )
          .timeout(_timeoutDuration);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "msg": "Password changed successfully"};
      } else {
        return {
          "success": false,
          "msg": data["detail"] ?? "Failed to change password",
        };
      }
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {"success": false, "msg": "An error occurred: ${e.toString()}"};
    }
  }

  // Update Profile
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
    required String location,
    required String district,
    required String state,
    File? profileImage,
  }) async {
    final url = Uri.parse("$baseUrl/auth/update-profile");
    try {
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['name'] = name
        ..fields['email'] = email
        ..fields['phone'] = phone
        ..fields['location'] = location
        ..fields['district'] = district
        ..fields['state'] = state;

      // Add profile image if selected
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile_image', profileImage.path),
        );
      }

      final streamedResponse = await request.send().timeout(_timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "msg": data["message"] ?? "Profile updated successfully",
        };
      } else {
        return {
          "success": false,
          "msg": data["detail"] ?? "Failed to update profile",
        };
      }
    } on TimeoutException {
      return {
        "success": false,
        "msg": "Connection timed out. Please check your network.",
      };
    } catch (e) {
      return {"success": false, "msg": "An error occurred: ${e.toString()}"};
    }
  }
}
