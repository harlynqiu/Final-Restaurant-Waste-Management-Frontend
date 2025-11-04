// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                            color:
                                _gpsActive ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 25),

            // Vehicle Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 4,
              shadowColor: darwcosGreen.withOpacity(0.3),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/images/driver.png",
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vehicle Information",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _infoRow("🚗 Type:", vehicle),
                          _infoRow("🪪 License:", license),
                          _infoRow("📊 Status:", status.toUpperCase()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

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
                  subtitle: "View your pickup history",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CompletedPickupsScreen()),
                    );
                  },
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
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
              MaterialPageRoute(
                  builder: (_) => const AvailablePickupsScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DriverPickupsScreen()),
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

  // 🌿 Clean White Sidebar
  Drawer _buildDrawer(String name, String status) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundImage:
                        const AssetImage("assets/images/driver.png"),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Status: ${status.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 13,
                            color: status.toLowerCase() == "active"
                                ? darwcosGreen
                                : Colors.redAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Menu
            Expanded(
              child: ListView(
                children: [
                  _drawerItem(Icons.dashboard_outlined, "Dashboard",
                      () => Navigator.pop(context)),
                  _drawerItem(Icons.list_alt_rounded, "Available Pickups", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AvailablePickupsScreen()),
                    );
                  }),
                  _drawerItem(Icons.local_shipping_outlined, "My Pickups", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DriverPickupsScreen()),
                    );
                  }),
                  _drawerItem(Icons.history_rounded, "Completed Pickups", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CompletedPickupsScreen()),
                    );
                  }),
                  _drawerItem(Icons.settings_outlined, "Settings (Soon)", () {}),
                ],
              ),
            ),

            // Logout + Footer
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: _logout,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "D.A.R.W.C.O.S Driver",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: darwcosGreen, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        hoverColor: darwcosGreen.withOpacity(0.08),
        onTap: onTap,
      ),
    );
  }
}
