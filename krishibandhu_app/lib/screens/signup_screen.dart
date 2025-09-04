import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService(); // ✅ Use instance
  String name = "", email = "", password = "";
  bool loading = false;

  void submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => loading = true);

    final result = await apiService.signup(name, email, password); // ✅ Use instance

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["success"] ? "Signup successful!" : result["msg"]),
        backgroundColor: result["success"] ? Colors.green : Colors.red,
      ),
    );

    if (result["success"]) {
      // Navigate to login screen or dashboard
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Name"),
                onSaved: (val) => name = val!.trim(),
                validator: (val) => val!.isEmpty ? "Enter name" : null,
              ),
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
                      onPressed: submit, child: const Text("Signup")),
            ],
          ),
        ),
      ),
    );
  }
}
