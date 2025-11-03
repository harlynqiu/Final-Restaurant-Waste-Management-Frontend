import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // ❌ Commented out since Firebase not used yet
// import 'firebase_options.dart'; // ❌ Commented out — generated later when you link Firebase

// -------------------
// 🖥️ Screen Imports
// -------------------
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/available_pickups_screen.dart';
import 'screens/pickup_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase init removed — will re-enable once Firebase is configured
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // -------------------
      // 🔰 Initial Route
      // -------------------
      initialRoute: '/login',

      // -------------------
      // 🧭 App Routes
      // -------------------
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/available-pickups': (context) => const AvailablePickupsScreen(),
      },

      // -------------------
      // 🗺️ Dynamic Route for Map
      // -------------------
      onGenerateRoute: (settings) {
        if (settings.name == '/pickup-map') {
          final args =
              settings.arguments as Map<String, dynamic>? ?? <String, dynamic>{};
          return MaterialPageRoute(
            builder: (context) => PickupMapScreen(
              pickupId: args['pickupId'] ?? 0,
              address: args['address'] ?? 'Unknown Address',
            ),
          );
        }

        // Fallback route if something goes wrong
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
