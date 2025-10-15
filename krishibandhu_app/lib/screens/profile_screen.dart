import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String token;
  const ProfileScreen({super.key, required this.token});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? profile;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  void fetchProfile() async {
    setState(() => loading = true);
    final res = await apiService.getProfile(widget.token);
    setState(() {
      profile = res;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
              ? const Center(child: Text("No data"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name: ${profile!['name']}"),
                      Text("Email: ${profile!['email']}"),
                    ],
                  ),
                ),
    );
  }
}
