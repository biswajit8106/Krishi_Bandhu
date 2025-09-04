import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart'; // ✅ Import signup screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();
  String email = "", password = "";
  bool loading = false;

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => loading = true);

    final result = await apiService.login(email, password);

    setState(() => loading = false);

    if (result["success"]) {
      final token = result["data"]["access_token"];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(token: token)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["msg"]),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navigateToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Email"),
                onSaved: (val) => email = val!.trim(),
                validator: (val) => val!.isEmpty ? "Enter email" : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                onSaved: (val) => password = val!.trim(),
                validator: (val) => val!.length < 6 ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 20),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: submit, child: const Text("Login")),
              const SizedBox(height: 10),
              TextButton(
                onPressed: navigateToSignup,
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
