import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? selectedState;
  String? selectedLanguage;
  bool agreeTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool loading = false;

  final List<String> states = ["Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Te0langana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"];
  final List<String> languages = ["English", "Hindi", "Marathi", "Tamil", "Telugu", "Kannada", "Gujarati", "Punjabi", "Odia", "Bengali"];

  void submit() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final state = selectedState;
    final language = selectedLanguage;

    if (name.isEmpty || phone.isEmpty || password.isEmpty || state == null || language == null || !agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields and agree to terms.")),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }
    setState(() => loading = true);
    final result = await apiService.signup(
      name: name,
      phone: phone,
      email: email.isEmpty ? null : email,
      password: password,
      state: state,
      language: language,
    );
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["success"] ? "Signup successful!" : result["msg"]),
        backgroundColor: result["success"] ? Colors.green : Colors.red,
      ),
    );
    if (result["success"]) {
      Navigator.pop(context);
    }
  }

  void navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDF5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 50),
            const Icon(Icons.agriculture, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 10),
            Text("Create Your Account",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    )),
            const SizedBox(height: 5),
            const Text("Join India’s Digital Farming Community",
                style: TextStyle(color: Colors.black54)),

            const SizedBox(height: 30),

            // Full Name
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // Phone
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: TextButton(
                  onPressed: () {},
                  child: const Text("Send OTP"),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // Email
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email (Optional)",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // Password
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // Confirm Password
            TextField(
              controller: confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // State Dropdown
            DropdownButtonFormField<String>(
              value: selectedState,
              items: states
                  .map((state) =>
                      DropdownMenuItem(value: state, child: Text(state)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedState = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Select State",
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // Language Dropdown
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              items: languages
                  .map((lang) =>
                      DropdownMenuItem(value: lang, child: Text(lang)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Preferred Language",
                prefixIcon: const Icon(Icons.language),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),

            // Terms & Conditions
            Row(
              children: [
                Checkbox(
                  value: agreeTerms,
                  onChanged: (value) {
                    setState(() {
                      agreeTerms = value ?? false;
                    });
                  },
                ),
                const Expanded(
                    child: Text(
                        "I agree to the Terms & Conditions and Privacy Policy"))
              ],
            ),

            const SizedBox(height: 20),

            // Signup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: loading ? null : submit,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 20),

            // Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: navigateToLogin,
                  child: const Text("Login",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
