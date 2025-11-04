// lib/screens/driver_pickups_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'pickup_map_screen.dart';
import 'pickup_detail_screen.dart';

class DriverPickupsScreen extends StatefulWidget {
  const DriverPickupsScreen({super.key});

  @override
  State<DriverPickupsScreen> createState() => _DriverPickupsScreenState();
}

class _DriverPickupsScreenState extends State<DriverPickupsScreen> {
  bool _loading = true;
  List<dynamic> _allPickups = [];
  String _error = "";
  String _searchQuery = "";

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  // ---------------- LOAD PICKUPS ----------------
  Future<void> _loadPickups() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("🔑 Access token: ${prefs.getString('access_token')}");

    try {
      final data = await ApiService.getAssignedPickups();

      // ✅ Convert accepted pickups to in-progress automatically
      for (final p in data) {
        if (p['status'].toString().toUpperCase() == "ACCEPTED") {
          await ApiService.startPickup(p['id']);
        }
      }

      final refreshed = await ApiService.getAssignedPickups();

      setState(() {
        _allPickups = refreshed;
        _loading = false;
        _error = "";
      });
    } catch (e) {
      setState(() {
        _error = "❌ Failed to load pickups: $e";
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async => _loadPickups();

  // ---------------- STATUS COLOR ----------------
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Colors.grey;
      case "ACCEPTED":
      case "IN_PROGRESS":
        return Colors.orange;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  // ---------------- FORMAT DATE ----------------
  String _formatDate(dynamic dateString) {
    try {
      if (dateString != null &&
          dateString.toString().isNotEmpty &&
          dateString.toString().toLowerCase() != "null") {
        final parsed = DateTime.parse(dateString.toString());
        return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
      }
      return "No scheduled date";
    } catch (_) {
      return "Invalid date";
    }
  }

  // ---------------- FILTER + GROUP ----------------
  List<dynamic> _filterByStatus(String status) {
    final filtered = _allPickups.where((p) {
      final s = (p['status'] ?? '').toString().toUpperCase();
      final matchStatus = s == status;
      final query = _searchQuery.toLowerCase();
      final restaurant = (p['restaurant_name'] ?? '').toLowerCase();
      final address = (p['pickup_address'] ?? '').toLowerCase();
      final type = (p['waste_type'] ?? '').toLowerCase();
      return matchStatus &&
          (restaurant.contains(query) ||
              address.contains(query) ||
              type.contains(query));
    }).toList();
    filtered.sort((a, b) =>
        (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    return filtered;
  }

  // ---------------- BUILD CARD ----------------
  Widget _buildCard(Map<String, dynamic> pickup) {
    final address = pickup['pickup_address'] ?? "No Address";
    final wasteType = pickup['waste_type'] ?? "N/A";
    final weight = pickup['weight_kg'] ?? "0";
    final status = (pickup['status'] ?? 'Unknown').toString().toUpperCase();
    final date = _formatDate(pickup['scheduled_date'] ?? pickup['created_at']);
    final statusColor = _statusColor(status);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: () async {
          // ✅ When tapping, open details (where “Complete” is available)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PickupDetailScreen(pickup: pickup),
            ),
          );
          if (result == true) {
            _loadPickups();
          }
        },
        child: Card(
          color: Colors.white,
          elevation: 3,
          shadowColor: darwcosGreen.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status + map icon
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.map,
                          color: darwcosGreen, size: 20),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PickupMapScreen(
                              pickupId: pickup['id'],
                              address: address,
                              latitude: double.tryParse(
                                  pickup['latitude']?.toString() ?? ''),
                              longitude: double.tryParse(
                                  pickup['longitude']?.toString() ?? ''),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "🗑 $wasteType • ⚖ $weight kg",
                  style: const TextStyle(fontSize: 13.5, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  "📅 $date",
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 10),

                // ✅ No more “Start” button; show info only
                if (status == "IN_PROGRESS")
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "In Progress...",
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (status == "COMPLETED")
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Completed",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- BUILD SECTION ----------------
  Widget _buildHorizontalSection(String title, List<dynamic> items,
      {String? imagePath}) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Image.asset(
                    imagePath,
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darwcosGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) => _buildCard(items[index]),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- BUILD UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: darwcosGreen)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Assigned Pickups",
              style: TextStyle(color: darwcosGreen)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: darwcosGreen),
        ),
        body: Center(child: Text(_error)),
      );
    }

    final inProgress = _filterByStatus("IN_PROGRESS");
    final completed = _filterByStatus("COMPLETED");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Assigned Pickups",
            style: TextStyle(
                color: darwcosGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: darwcosGreen),
              onPressed: _refresh)
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: darwcosGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: "Search pickups...",
                  prefixIcon: const Icon(Icons.search, color: darwcosGreen),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildHorizontalSection("In Progress", inProgress,
                  imagePath: "assets/images/in_progress.png"),
              _buildHorizontalSection("Completed", completed,
                  imagePath: "assets/images/complete.png"),

              if (inProgress.isEmpty && completed.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Text(
                      "No active pickups yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
