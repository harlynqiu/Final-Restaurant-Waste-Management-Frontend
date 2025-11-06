// lib/screens/pickup_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PickupDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pickup;

  const PickupDetailScreen({super.key, required this.pickup});

  static const Color darwcosGreen = Color(0xFF015704);

  // ✅ Pretty label for status
  String _prettyStatus(String status) {
    switch (status) {
      case "PENDING":
        return "Awaiting Driver";
      case "ACCEPTED":
        return "Driver Assigned";
      case "IN_PROGRESS":
        return "In Progress";
      case "COMPLETED":
        return "Completed";
      case "CANCELLED":
        return "Cancelled";
      default:
        return status;
    }
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return "No schedule";
      final parsed = DateTime.parse(date.toString());
      return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return "Invalid date";
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Colors.orange;
      case "ACCEPTED":
        return Colors.blueGrey;
      case "IN_PROGRESS":
        return Colors.blueAccent;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusRaw = pickup["status"]?.toString().toUpperCase() ?? "UNKNOWN";

    final statusColor = _statusColor(statusRaw);
    final statusLabel = _prettyStatus(statusRaw);  // ✅ Use pretty label

    final wasteType = pickup["waste_type"] ?? "Unknown";
    final weight = pickup["weight_kg"]?.toString() ?? "0";
    final scheduledDate =
        _formatDate(pickup["scheduled_date"] ?? pickup["created_at"]);
    final address = pickup["pickup_address"] ?? "No address specified";
    final donationDrive =
        pickup["donation_drive_title"] ?? "No donation drive linked";
    final driver = pickup["driver_name"] ?? "No driver assigned";

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
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Status Row (NOW USES PRETTY LABEL)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,      // ✅ FIXED!
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.recycling,
                          size: 32, color: darwcosGreen),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ✅ Address
                  _sectionTitle("Pickup Location:"),
                  Text(
                    address,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.black87, height: 1.4),
                  ),
                  _divider(),

                  // ✅ Waste
                  _sectionTitle("Waste Type:"),
                  _sectionValue(wasteType),

                  const SizedBox(height: 12),

                  // ✅ Weight
                  _sectionTitle("Weight (kg):"),
                  _sectionValue("$weight kg"),

                  const SizedBox(height: 12),

                  // ✅ Schedule
                  _sectionTitle("Scheduled Pickup:"),
                  _sectionValue(scheduledDate),

                  _divider(),

                  // ✅ Donation Drive
                  _sectionTitle("Donation Drive:"),
                  _sectionValue(donationDrive),

                  const SizedBox(height: 12),

                  // ✅ Driver name
                  _sectionTitle("Assigned Driver:"),
                  _sectionValue(driver),

                  const SizedBox(height: 25),

                  // ✅ Info message based on status
                  _infoMessage(statusRaw),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Styled section header
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: darwcosGreen,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  // ✅ Styled value
  Widget _sectionValue(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
    );
  }

  // ✅ Divider
  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Divider(color: Colors.grey[300], thickness: 1),
    );
  }

  // ✅ Info message widget
  Widget _infoMessage(String status) {
    IconData icon;
    String text;
    Color color;

    switch (status) {
      case "ACCEPTED":
        icon = Icons.verified;
        color = Colors.blueGrey;
        text = "A driver has accepted your pickup. They will start it soon.";
        break;

      case "IN_PROGRESS":
        icon = Icons.local_shipping;
        color = Colors.blueAccent;
        text = "Your driver is currently completing this pickup.";
        break;

      case "PENDING":
        icon = Icons.schedule;
        color = Colors.orangeAccent;
        text = "Your pickup is waiting for a driver.";
        break;

      case "COMPLETED":
        icon = Icons.check_circle;
        color = Colors.green;
        text =
            "This pickup is completed. Your reward points have been updated.";
        break;

      default:
        icon = Icons.info_outline;
        color = Colors.grey;
        text = "Pickup status update.";
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ),
      ],
    );
  }
}
