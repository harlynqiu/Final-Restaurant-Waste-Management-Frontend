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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Pickup"),
        content: const Text("Are you sure you want to cancel this pickup?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final success = await ApiService.updateTrashPickup(
        widget.pickup['id'],
        {"status": "cancelled"},
      );

      if (success) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pickup cancelled successfully")),
        );
      } else {
        throw Exception("Failed to cancel pickup");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pickup;
    final status = p['status']?.toString().toUpperCase() ?? "UNKNOWN";
    final wasteType = p['waste_type'] ?? "Unknown";
    final weight = p['trash_weight']?.toString() ?? "0";
    final scheduled = p['scheduled_date'] != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(p['scheduled_date']))
        : "No schedule";
    final address = p['address'] ?? p['restaurant_name'] ?? "No address provided";

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
                      // Header
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
                          Icon(Icons.recycling, color: darwcosGreen),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Address
                      Text(
                        "Address:",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Waste type
                      Text(
                        "Waste Type:",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wasteType,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Weight
                      Text(
                        "Weight (kg):",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weight,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Scheduled Date
                      Text(
                        "Scheduled Date:",
                        style: TextStyle(
                          color: darwcosGreen.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scheduled,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 30),

                      // Cancel Button (if pending or in progress)
                      if (status == "PENDING" || status == "IN_PROGRESS")
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _cancelPickup,
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text(
                              "Cancel Pickup",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
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
