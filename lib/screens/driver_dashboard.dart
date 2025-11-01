// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'available_pickups_screen.dart';
import 'driver_pickups_screen.dart';

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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDriver();
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.drain();
    super.dispose();
  }

  Future<void> _loadDriver() async {
    try {
      final data = await ApiService.getCurrentDriver();
      if (!mounted) return;
      setState(() {
        _driver = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "❌ Failed to load driver profile: $e";
        _loading = false;
      });
    }
  }

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
          const SnackBar(content: Text("Location permission denied")),
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
      debugPrint("GPS error: $e");
      setState(() => _gpsActive = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: darwcosGreen.withOpacity(0.1),
                child: Icon(icon, size: 32, color: darwcosGreen),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    final driverName = _driver?["full_name"] ?? "Driver";
    final status = _driver?["status"] ?? "inactive";
    final vehicle = _driver?["vehicle_type"] ?? "-";
    final license = _driver?["license_number"] ?? "-";

    return RefreshIndicator(
      onRefresh: _loadDriver,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      child: Image.asset(
                        "assets/images/black_philippine_eagle.png",
                        height: 60,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, $driverName!",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: darwcosGreen,
                          ),
                        ),
                        Text(
                          _gpsActive ? "GPS Active 🛰️" : "GPS Inactive ⚠️",
                          style: TextStyle(
                            color: _gpsActive ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Vehicle Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Vehicle Information",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Text("Type: $vehicle"),
                    Text("License: $license"),
                    Text("Status: ${status.toUpperCase()}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Dashboard Menu Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
              children: [
                _buildDashboardCard(
                  icon: Icons.list_alt_rounded,
                  title: "Available Pickups",
                  subtitle: "View unassigned pickups",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AvailablePickupsScreen()),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.local_shipping_rounded,
                  title: "My Pickups",
                  subtitle: "View your assigned pickups",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DriverPickupsScreen()),
                    );
                  },
                ),
                _buildDashboardCard(
                  icon: Icons.history_rounded,
                  title: "Completed Pickups",
                  subtitle: "History (coming soon)",
                ),
                _buildDashboardCard(
                  icon: Icons.settings,
                  title: "Profile & Settings",
                  subtitle: "Manage account (coming soon)",
                ),
              ],
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "D.A.R.W.C.O.S – Driver Mode",
                style: TextStyle(
                  color: darwcosGreen,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
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
      drawer: _buildDrawer(_driver?["full_name"] ?? "Driver",
          _driver?["status"] ?? "inactive"),
      body: _buildMainDashboard(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: darwcosGreen,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AvailablePickupsScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverPickupsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded), label: "Available"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_rounded), label: "My Pickups"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  Drawer _buildDrawer(String name, String status) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: darwcosGreen),
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text("Status: ${status.toUpperCase()}"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.local_shipping, color: darwcosGreen, size: 36),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
