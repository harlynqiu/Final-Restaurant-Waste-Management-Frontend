import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
//import 'driver_dashboard.dart';
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

  // ---------------- LOGIN FUNCTION ----------------
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both username and password.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ApiService.login(username, password);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid username or password.")),
      );
      return;
    }

    try {
      final user = await ApiService.getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString("role") ?? user?["role"] ?? "owner";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Login successful as $role!")),
      );

      Widget targetScreen =
          role.toLowerCase() == "driver" ? const DriverDashboardScreen() : const DashboardScreen();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error fetching user info: $e")),
      );
    }
  }

  // ---------------- UI ----------------
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
                // 🦅 App Logo
                Image.asset(
                  "assets/images/white_eagle_logo.png",
                  width: 120,
                ),
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

                // 🗂 Login Form Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Sign In",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: darwcosGreen,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username Field
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: "Email or Username",
                            labelStyle: TextStyle(color: darwcosGreen),
                            prefixIcon: Icon(Icons.person, color: darwcosGreen),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: darwcosGreen),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: darwcosGreen, width: 2),
                            ),
                          ),
                          cursorColor: darwcosGreen,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: const TextStyle(color: darwcosGreen),
                            prefixIcon: const Icon(Icons.lock, color: darwcosGreen),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: darwcosGreen),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: darwcosGreen, width: 2),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: darwcosGreen,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          cursorColor: darwcosGreen,
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: darwcosGreen),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Sign In Button
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

                        // Divider
                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text("or"),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sign up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New User? "),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darwcosGreen,
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

                // Footer Text
                const Text(
                  "Radiate Pride. Radiate Cleanliness.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: darwcosGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
