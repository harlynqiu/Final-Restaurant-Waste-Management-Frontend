// lib/screens/driver_dashboard.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'available_pickups_screen.dart';
import 'driver_pickups_screen.dart';
import 'completed_pickups_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  static const Color darwcosGreen = Color(0xFF015704);

  bool _loading = true;
  String _error = "";
  Map<String, dynamic>? _driver;

  bool _gpsActive = false;
  Stream<Position>? _positionStream;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _validateRole();
  }

  @override
  void dispose() {
    _positionStream?.drain();
    super.dispose();
  }

  // ======================================================
  // ✅ STEP 1 — CHECK ROLE + TOKEN (FIXED)
  // ======================================================
  Future<void> _validateRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("role");
    final token = prefs.getString("access_token");

    debugPrint("CHECK ROLE: $role");
    debugPrint("CHECK TOKEN: $token");

    // ✅ FIX: Must have role = driver AND a valid token
    if (role != "driver" || token == null || token.isEmpty) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired or invalid. Please log in again."),
            backgroundColor: Colors.redAccent,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });

      return;
    }

    // ✅ If everything is valid → proceed
    _loadDriver();
    _startLiveTracking();
  }

  // ======================================================
  // ✅ LOAD DRIVER PROFILE
  // ======================================================
  Future<void> _loadDriver() async {
    try {
      final data = await ApiService.getCurrentDriver();
      if (!mounted) return;

      setState(() {
        _driver = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load driver profile: $e";
        _loading = false;
      });
    }
  }

  // ======================================================
  // ✅ LIVE GPS TRACKING
  // ======================================================
  Future<void> _startLiveTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission denied"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _gpsActive = true);

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      _positionStream!.listen((Position position) async {
        await ApiService.updateDriverLocation(
          position.latitude,
          position.longitude,
        );
      });
    } catch (e) {
      setState(() => _gpsActive = false);
    }
  }

  // ======================================================
  // ✅ LOGOUT
  // ======================================================
  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ======================================================
  // ✅ SIDEBAR
  // ======================================================
  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: darwcosGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset("assets/images/black_philippine_eagle.png",
                      height: 60),
                  const SizedBox(height: 12),
                  Text(
                    _driver?["full_name"] ?? "Driver",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _driver?["vehicle_type"] ?? "",
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.list_alt_rounded, color: darwcosGreen),
              title: const Text("Available Pickups"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AvailablePickupsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_rounded,
                  color: darwcosGreen),
              title: const Text("My Pickups"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DriverPickupsScreen()),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.history_rounded, color: darwcosGreen),
              title: const Text("Completed Pickups"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompletedPickupsScreen()),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent),
              title: const Text("Logout"),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // ✅ REUSABLE CARD
  // ======================================================
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: darwcosGreen.withOpacity(0.1),
              child: Icon(icon, size: 30, color: darwcosGreen),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // ✅ MAIN DASHBOARD CONTENT
  // ======================================================
  Widget _buildMainDashboard() {
    final driverName = _driver?["full_name"] ?? "Driver";
    final status = _driver?["status"] ?? "inactive";
    final vehicle = _driver?["vehicle_type"] ?? "-";
    final license = _driver?["license_number"] ?? "-";

    return RefreshIndicator(
      onRefresh: _loadDriver,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Image.asset(
                    "assets/images/black_philippine_eagle.png",
                    height: 55,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, $driverName!",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darwcosGreen,
                        ),
                      ),
                      Text(
                        _gpsActive ? "GPS Active 🛰️" : "GPS Inactive ⚠️",
                        style: TextStyle(
                          color:
                              _gpsActive ? Colors.green : Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/driver.png",
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vehicle Information",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          _infoRow("Type", vehicle),
                          _infoRow("License", license),
                          _infoRow("Status", status.toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.05,
              children: [
                _buildDashboardCard(
                  icon: Icons.list_alt_rounded,
                  title: "Available Pickups",
                  subtitle: "View unassigned pickups",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AvailablePickupsScreen()),
                  ),
                ),
                _buildDashboardCard(
                  icon: Icons.local_shipping_rounded,
                  title: "My Pickups",
                  subtitle: "View assigned pickups",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DriverPickupsScreen()),
                  ),
                ),
                _buildDashboardCard(
                  icon: Icons.history_rounded,
                  title: "Completed Pickups",
                  subtitle: "View pickup history",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CompletedPickupsScreen()),
                  ),
                ),
                _buildDashboardCard(
                  icon: Icons.settings,
                  title: "Profile & Settings",
                  subtitle: "Coming soon",
                ),
              ],
            ),

            const SizedBox(height: 35),
            Center(
              child: Text(
                "D.A.R.W.C.O.S – Driver Mode",
                style: TextStyle(
                  color: darwcosGreen,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: darwcosGreen,
          title: const Text("Driver Dashboard"),
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      drawer: _buildSidebar(),
      body: _buildMainDashboard(),
    );
  }
}
