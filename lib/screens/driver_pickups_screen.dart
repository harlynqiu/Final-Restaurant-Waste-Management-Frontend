// lib/screens/driver_pickups_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'pickup_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // ✅ Needed for decoding backend response

class DriverPickupsScreen extends StatefulWidget {
  const DriverPickupsScreen({super.key});

  @override
  State<DriverPickupsScreen> createState() => _DriverPickupsScreenState();
}

class _DriverPickupsScreenState extends State<DriverPickupsScreen> {
  bool _loading = true;
  List<dynamic> _pickups = [];
  String _error = "";

  static const Color darwcosGreen = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  Future<void> _loadPickups() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("🔑 Access token: ${prefs.getString('access_token')}");

    try {
      final data = await ApiService.getAssignedPickups();
      setState(() {
        _pickups = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "❌ Failed to load pickups: $e";
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async => _loadPickups();

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Colors.grey;
      case "ACCEPTED":
        return Colors.orange;
      case "IN_PROGRESS":
        return Colors.blue;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  // 🟠 START PICKUP
  Future<void> _startPickup(int pickupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start Pickup"),
        content: const Text("Are you now on the way to this pickup?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirmed ?? false) {
      final ok = await ApiService.startPickup(pickupId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚀 Pickup marked as In Progress")),
        );
        _refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to update status")),
        );
      }
    }
  }

  // ✅ COMPLETE PICKUP + Reward Dialog
  Future<void> _completePickup(int pickupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complete Pickup"),
        content: const Text("Are you sure you want to mark this pickup as completed?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirmed ?? false) {
      final response = await ApiService.completePickupDetailed(pickupId);

      if (response['success'] == true && mounted) {
        final pointsAdded = response['points_added'] ?? 0;
        final totalPoints = response['total_points'] ?? 0;

        // 🎉 Reward Success Dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("✅ Pickup Completed"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Great job! You’ve successfully completed this pickup."),
                const SizedBox(height: 8),
                Text(
                  "+$pointsAdded Points Added",
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text("Total Points: $totalPoints 🪙",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );

        _refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to complete pickup")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: darwcosGreen)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Assigned Pickups"), backgroundColor: darwcosGreen),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Pickups"),
        backgroundColor: darwcosGreen,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _pickups.isEmpty
            ? const Center(child: Text("No assigned pickups yet."))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pickups.length,
                itemBuilder: (context, index) {
                  final pickup = _pickups[index];
                  final date = pickup['scheduled_date'] ?? '';
                  final formattedDate = date.isNotEmpty
                      ? DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(date))
                      : 'No Date';
                  final status = (pickup['status'] ?? 'Unknown').toString().toUpperCase();
                  final address = pickup['pickup_address'] ?? 'No Address';
                  final wasteType = pickup['waste_type'] ?? 'N/A';
                  final weight = pickup['weight_kg'] ?? '0';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.recycling, color: _statusColor(status)),
                            title: Text(address, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Type: $wasteType"),
                                Text("Weight: ${weight}kg"),
                                Text("Date: $formattedDate"),
                                Text("Status: $status",
                                    style: TextStyle(
                                        color: _statusColor(status),
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.map, color: darwcosGreen),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PickupMapScreen(
                                      pickupId: pickup['id'],
                                      address: address,
                                      latitude: pickup['latitude'] != null
                                          ? double.tryParse(pickup['latitude'].toString())
                                          : null,
                                      longitude: pickup['longitude'] != null
                                          ? double.tryParse(pickup['longitude'].toString())
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 🟠 START PICKUP button
                          if (status == "ACCEPTED")
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Start Pickup"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _startPickup(pickup['id']),
                            ),

                          // ✅ COMPLETE button
                          if (status == "IN_PROGRESS")
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Complete Pickup"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darwcosGreen,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _completePickup(pickup['id']),
                            ),

                          if (status == "COMPLETED")
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                "✅ Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
