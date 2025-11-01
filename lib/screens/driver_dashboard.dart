// lib/screens/driver_dashboard.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  // --------------------------
  // Load driver profile
  // --------------------------
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
        _error = "Failed to load driver profile: $e";
        _loading = false;
      });
    }
  }

  // --------------------------
  // Update driver status
  // --------------------------
  Future<void> _updateStatus(String newStatus) async {
    try {
      final success = await ApiService.updateDriverStatus(newStatus);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Status updated to $newStatus")),
        );
        _loadDriver(); // refresh
      } else {
        throw Exception("Server rejected the update");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Failed: $e")));
    }
  }

  // --------------------------
  // Logout
  // --------------------------
  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void initState() {
    super.initState();
    _loadDriver();
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

    final name = _driver?["full_name"] ?? "Driver";
    final status = _driver?["status"] ?? "unknown";
    final vehicle = _driver?["vehicle_type"] ?? "-";
    final plate = _driver?["plate_number"] ?? "-";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darwcosGreen,
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Greeting
          Text(
            "Welcome, $name 👋",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Vehicle info
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  Text("Type: $vehicle"),
                  Text("Plate No: $plate"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Current Status
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.radio_button_on,
                      color: status == "available"
                          ? Colors.green
                          : status == "on_pickup"
                              ? Colors.orange
                              : Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Status: ${status[0].toUpperCase()}${status.substring(1)}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status == "available"
                              ? "You are available for new pickups."
                              : status == "on_pickup"
                                  ? "You are currently handling a pickup."
                                  : "You are offline.",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _updateStatus(value),
                    icon: const Icon(Icons.edit, color: Colors.black54),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "available",
                        child: Text("Available"),
                      ),
                      const PopupMenuItem(
                        value: "on_pickup",
                        child: Text("On Pickup"),
                      ),
                      const PopupMenuItem(
                        value: "inactive",
                        child: Text("Inactive"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Logout
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: darwcosGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Log Out",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }
}
