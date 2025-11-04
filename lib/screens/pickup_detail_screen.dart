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

  // ---------------- COMPLETE PICKUP ----------------
  Future<void> _completePickup() async {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Mark as Complete",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: darwcosGreen,
          ),
        ),
        content: const Text(
          "Are you sure you want to mark this pickup as completed?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: darwcosGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Yes, Complete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.completePickupDetailed(id);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result["success"] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${result["message"]}"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pickup completed successfully!"),
          backgroundColor: darwcosGreen,
        ),
      );

      Navigator.pop(context, true); 
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error completing pickup: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
    final address =
        p['pickup_address'] ?? p['restaurant_name'] ?? "No address provided";
    final donationDrive =
        p['donation_drive_title'] ?? p['donation_drive'] ?? "No donation drive linked";

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
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: Colors.white,
                    elevation: 5,
                    shadowColor: darwcosGreen.withOpacity(0.1),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
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
                                  color: darwcosGreen, size: 28),
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
                            style: const TextStyle(
                                fontSize: 16, height: 1.4, color: Colors.black87),
                          ),
                          const Divider(height: 32),

                          // ---------------- WASTE TYPE ----------------
                          Text(
                            "Waste Type:",
                            style: TextStyle(
                              color: darwcosGreen.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(wasteType,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87)),
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
                          Text("$weight kg",
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87)),
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
                          Text(scheduled,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87)),

                          const Divider(height: 32),

                          // ---------------- DONATION DRIVE ----------------
                          Text(
                            "Donation Drive:",
                            style: TextStyle(
                              color: darwcosGreen.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            donationDrive,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 30),

                          // ---------------- COMPLETE BUTTON ----------------
                          if (status == "IN_PROGRESS")
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _completePickup,
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.white),
                                label: const Text(
                                  "Complete Pickup",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darwcosGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 26, vertical: 14),
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
              ),
            ),
    );
  }
}
