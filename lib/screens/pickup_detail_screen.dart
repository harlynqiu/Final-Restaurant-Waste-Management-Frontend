import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class PickupDetailScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;

  const PickupDetailScreen({super.key, required this.pickup});

  @override
  State<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends State<PickupDetailScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  bool _isLoading = false;

  // ---------------- CANCEL PICKUP ----------------
  Future<void> _cancelPickup() async {
    final dynamic rawId = widget.pickup['id'];
    final int? id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing pickup ID")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Cancellation"),
        content: const Text(
          "Are you sure you want to cancel this pickup?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final updatedPickup =
        await ApiService.updateTrashPickup(id, {"status": "CANCELLED"});

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (updatedPickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to cancel pickup. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final result = {
      ...widget.pickup,
      "status": "CANCELLED",
      "id": (updatedPickup as Map<String, dynamic>?)?["id"] ?? id,
    };

    Navigator.pop(context, {"refresh": true, "pickup": result});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Pickup cancelled successfully."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ---------------- SAFE DATE FORMATTER ----------------
  String _formatDate(dynamic dateString, {dynamic fallbackDate}) {
    try {
      if (dateString != null &&
          dateString.toString().isNotEmpty &&
          dateString.toString().toLowerCase() != "null") {
        final parsed = DateTime.parse(dateString.toString());
        return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
      }

      if (fallbackDate != null) {
        final parsed = DateTime.parse(fallbackDate.toString());
        return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
      }

      return "No scheduled date";
    } catch (e) {
      return "Invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pickup;

    final status = p['status']?.toString().toUpperCase() ?? "UNKNOWN";
    final wasteType = p['waste_type'] ?? "Unknown";
    final weight = p['weight_kg']?.toString() ?? "0";
    final scheduled = _formatDate(p['scheduled_date'] ?? p['created_at']);
    final address = p['pickup_address'] ?? p['restaurant_name'] ?? "No address provided";

    Color statusColor;
    switch (status) {
      case "COMPLETED":
        statusColor = Colors.green;
        break;
      case "PENDING":
        statusColor = Colors.orangeAccent;
        break;
      case "CANCELLED":
        statusColor = Colors.redAccent;
        break;
      case "IN_PROGRESS":
        statusColor = Colors.blueAccent;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Pickup Details",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- HEADER ----------------
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.recycling,
                              color: darwcosGreen, size: 26),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ---------------- LOCATION ----------------
                      Text(
                        "Pickup Location (Restaurant Address):",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      // ---------------- WASTE TYPE ----------------
                      Text(
                        "Waste Type:",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(wasteType, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),

                      // ---------------- WEIGHT ----------------
                      Text(
                        "Weight (kg):",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("$weight kg", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),

                      // ---------------- DATE ----------------
                      Text(
                        "Scheduled Pickup Date & Time:",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(scheduled, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 30),

                      // ---------------- CANCEL BUTTON ----------------
                      if (status == "PENDING" || status == "IN_PROGRESS")
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _cancelPickup,
                            icon: const Icon(Icons.cancel),
                            label: const Text("Cancel Pickup"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
}
