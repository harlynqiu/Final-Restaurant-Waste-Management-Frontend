// lib/screens/completed_pickups_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CompletedPickupsScreen extends StatefulWidget {
  const CompletedPickupsScreen({super.key});

  @override
  State<CompletedPickupsScreen> createState() =>
      _CompletedPickupsScreenState();
}

class _CompletedPickupsScreenState extends State<CompletedPickupsScreen> {
  bool _loading = true;
  String _error = "";
  List<dynamic> _completedPickups = [];

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _loadCompletedPickups();
  }

  // ------------------------------ LOAD COMPLETED PICKUPS ------------------------------
  Future<void> _loadCompletedPickups() async {
    try {
      final data = await ApiService.getAssignedPickups();
      setState(() {
        _completedPickups = data
            .where((p) =>
                (p['status'] ?? '').toString().toUpperCase() == 'COMPLETED')
            .toList();
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

  // ------------------------------ SAFE DATE FORMATTER ------------------------------
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

  // ------------------------------ BUILD UI ------------------------------
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
          title: const Text(
            "Completed Pickups",
            style: TextStyle(color: darwcosGreen),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: darwcosGreen),
          elevation: 2,
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Completed Pickups",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: darwcosGreen),
            tooltip: "Refresh",
            onPressed: _loadCompletedPickups,
          ),
        ],
      ),
      body: _completedPickups.isEmpty
          ? const Center(
              child: Text(
                "No completed pickups yet.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              itemCount: _completedPickups.length,
              itemBuilder: (context, index) {
                final pickup = _completedPickups[index];
                final restaurantName =
                    pickup['restaurant_name'] ?? "Unknown Restaurant";
                final address =
                    pickup['pickup_address'] ?? "No Address Provided";
                final wasteType = pickup['waste_type'] ?? "N/A";
                final weight = pickup['weight_kg']?.toString() ?? "0";
                final scheduled = _formatDate(
                    pickup['scheduled_date'] ?? pickup['created_at']);
                final points = pickup['reward_points'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Card(
                    color: Colors.white,
                    elevation: 5,
                    shadowColor: darwcosGreen.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---------------- HEADER ----------------
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "COMPLETED",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.check_circle_outline,
                                  color: Colors.green, size: 28),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ---------------- RESTAURANT ----------------
                          Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.3),
                          ),
                          const Divider(height: 30),

                          // ---------------- DETAILS ----------------
                          Row(
                            children: [
                              const Icon(Icons.recycling,
                                  color: darwcosGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Waste Type: ",
                                style: TextStyle(
                                  color: darwcosGreen.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(wasteType,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.scale,
                                  color: darwcosGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Weight: ",
                                style: TextStyle(
                                  color: darwcosGreen.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("$weight kg",
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  color: darwcosGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Completed on: ",
                                style: TextStyle(
                                  color: darwcosGreen.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  scheduled,
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Reward Points: ",
                                style: TextStyle(
                                  color: darwcosGreen.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text("$points pts",
                                  style: const TextStyle(
                                      color: Colors.black87, fontSize: 15)),
                            ],
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
