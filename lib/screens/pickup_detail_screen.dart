// lib/screens/pickup_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PickupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;

  const PickupDetailScreen({super.key, required this.pickup});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  static const Color darwcosGreen = Color(0xFF015704);

  bool _processing = false;
  bool _isDriver = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDriver = prefs.getString("role") == "driver";
    });
  }

  // ✅ Format date
  String _formatDate(dynamic date) {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a')
          .format(DateTime.parse(date.toString()));
    } catch (_) {
      return "Unknown";
    }
  }

  // ✅ Colors for status badge
  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "ACCEPTED":
        return Colors.orange;
      case "IN_PROGRESS":
        return Colors.blue;
      case "COMPLETED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ DRIVER ACTION: Start
  Future<void> _startPickup(int id) async {
    setState(() => _processing = true);
    final ok = await ApiService.startPickup(id);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, {"refresh": true});
    }

    setState(() => _processing = false);
  }

  // ✅ DRIVER ACTION: Complete
  Future<void> _completePickup(int id) async {
    setState(() => _processing = true);
    final ok = await ApiService.completePickup(id);

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, {"refresh": true});
    }

    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pickup;

    final id = p["id"];
    final status = p["status"].toString().toUpperCase();
    final address = p["pickup_address"] ?? "Unknown address";
    final wasteType = p["waste_type"] ?? "-";
    final weight = p["weight_kg"].toString();
    final date = _formatDate(p["scheduled_date"] ?? p["created_at"]);

    // ✅ User-only fields
    final donationDrive = p["donation_drive_title"] ?? "None";
    final driverName = p["driver_name"] ?? "No driver assigned";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Pickup Details",
          style: TextStyle(color: darwcosGreen, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == "ACCEPTED"
                      ? "Driver Assigned"
                      : status == "IN_PROGRESS"
                          ? "In Progress"
                          : status == "COMPLETED"
                              ? "Completed"
                              : status,
                  style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),

              const SizedBox(height: 22),

              // ✅ Location
              const Text("Pickup Location:",
                  style: TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(address,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.black87)),
              Divider(color: Colors.grey[300], height: 30),

              // ✅ Waste
              const Text("Waste Type:",
                  style: TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(wasteType,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 10),

              const Text("Weight:",
                  style: TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text("$weight kg",
                  style:
                      const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 10),

              const Text("Scheduled Pickup:",
                  style: TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(date,
                  style:
                      const TextStyle(fontSize: 16, color: Colors.black87)),
              Divider(color: Colors.grey[300], height: 30),

              // ✅ ONLY USER SEES THESE
              if (!_isDriver) ...[
                const Text("Donation Drive:",
                    style: TextStyle(
                        color: darwcosGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(donationDrive,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 15),

                const Text("Assigned Driver:",
                    style: TextStyle(
                        color: darwcosGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(driverName,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 25),
              ],

              // ✅ DRIVER ACTION BUTTONS
              if (_isDriver && status == "ACCEPTED")
                ElevatedButton(
                  onPressed: _processing ? null : () => _startPickup(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _processing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Start Pickup",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),

              if (_isDriver && status == "IN_PROGRESS")
                ElevatedButton(
                  onPressed: _processing ? null : () => _completePickup(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darwcosGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _processing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Complete Pickup",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),

              if (status == "COMPLETED")
                const Center(
                  child: Text("✅ Pickup Completed!",
                      style:
                          TextStyle(fontSize: 16, color: Colors.green)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
