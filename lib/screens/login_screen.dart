import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'driver_dashboard.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color darwcosGreen = Color(0xFF015704);

  // ======================================================
  // ✅ LOGIN FUNCTION — fixed with SharedPreferences
  // ======================================================
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnack("Please enter both username and password.");
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.loginUser(username, password);
    setState(() => _isLoading = false);

    if (result["success"] == false) {
      _showSnack(result["message"] ?? "Invalid login", isError: true);
      return;
    }

    final role = result["role"];
    final verified = result["verified"];

    if (!verified && role != "owner") {
      _showSnack("Account pending approval.", isWarning: true);
      return;
    }

    // ✅ Save role in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", role);
    await prefs.setBool("logged_in", true);

    _showSnack("Login successful as $role!", isSuccess: true);

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // ✅ Use named routes for navigation
    if (role == "driver") {
      Navigator.pushReplacementNamed(context, '/driver-dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  // ======================================================
  // ✅ SnackBar Helper
  // ======================================================
  void _showSnack(String msg,
      {bool isError = false, bool isSuccess = false, bool isWarning = false}) {
    Color color = Colors.black;
    if (isError) color = Colors.red;
    if (isSuccess) color = Colors.green;
    if (isWarning) color = Colors.orange;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ======================================================
  // ✅ UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Image.asset("assets/images/black_philippine_eagle.png",
                    width: 120),

                const SizedBox(height: 10),
                const Text(
                  "Welcome to D.A.R.W.C.O.S",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darwcosGreen,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Davao Restaurant Waste Collection & Segregation",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 30),

                // ---------------- LOGIN CARD ----------------
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    child: Column(
                      children: [
                        const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darwcosGreen,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: "Email or Username",
                            prefixIcon:
                                Icon(Icons.person, color: darwcosGreen),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: darwcosGreen),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: darwcosGreen, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon:
                                const Icon(Icons.lock, color: darwcosGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: darwcosGreen,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: darwcosGreen),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: darwcosGreen, width: 2),
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text("Forgot Password?",
                                style: TextStyle(color: darwcosGreen)),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          height: 50,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: darwcosGreen,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _login,
                                  child: const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New User? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignupScreen()),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: darwcosGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  "Radiate Pride. Radiate Cleanliness.",
                  style: TextStyle(
                      color: darwcosGreen,
                      fontSize: 14,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
