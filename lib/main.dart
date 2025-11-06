import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -------------------
// 🖥️ Screen Imports
// -------------------
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/driver_dashboard.dart';
import 'screens/available_pickups_screen.dart';
import 'screens/pickup_map_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color darwcosGreen = Color(0xFF015704);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Waste Management',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: darwcosGreen),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: darwcosGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
      ),

      // ✅ AUTO ROUTING BASED ON ROLE
      home: const RoleRouter(),

      // ✅ ROUTES — FIXED (NO MORE const DRIVER DASHBOARD)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),

        // ❌ removed const
        '/driver-dashboard': (context) => DriverDashboardScreen(),

        // ❌ removed const
        '/available-pickups': (context) => AvailablePickupsScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/pickup-map') {
          final args = settings.arguments as Map<String, dynamic>? ??
              <String, dynamic>{};

          return MaterialPageRoute(
            builder: (context) => PickupMapScreen(
              pickupId: args['pickupId'] ?? 0,
              address: args['address'] ?? 'Unknown Address',
            ),
          );
        }

        // ✅ fallback page
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text(
                '404 - Page Not Found',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}

//
// ✅ BOOT SCREEN: Checks SharedPreferences
//
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final loggedIn = prefs.getBool("logged_in") ?? false;
    final role = prefs.getString("role");

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    if (!loggedIn || role == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (role == "driver") {
      // ❌ removed const
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DriverDashboardScreen()),
      );
      return;
    }

    // ✅ owner dashboard remains const
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF015704),
        ),
      ),
    );
  }
}
