// lib/screens/available_pickups_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AvailablePickupsScreen extends StatefulWidget {
  const AvailablePickupsScreen({super.key});

  @override
  State<AvailablePickupsScreen> createState() => _AvailablePickupsScreenState();
}

class _AvailablePickupsScreenState extends State<AvailablePickupsScreen> {
  bool _loading = true;
  String _error = "";
  List<dynamic> _availablePickups = [];

  static const Color darwcosGreen = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadAvailablePickups();
  }

  // ------------------------------
  // 🟢 Load available pickups
  // ------------------------------
  Future<void> _loadAvailablePickups() async {
    try {
      final data = await ApiService.getAvailablePickups();
      setState(() {
        _availablePickups = data;
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

  // ------------------------------
  // 🚗 Accept pickup and redirect to map
  // ------------------------------
  Future<void> _acceptPickup(int pickupId, String address) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Processing pickup acceptance...")),
      );

      final success = await ApiService.acceptPickup(pickupId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pickup accepted successfully!")),
        );

        // ✅ Redirect to map screen with pickup details
        Navigator.pushReplacementNamed(
          context,
          '/pickup-map',
          arguments: {
            'pickupId': pickupId,
            'address': address,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to accept pickup. Try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    }
  }

  // ------------------------------
  // 🧱 Build UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: darwcosGreen)),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: darwcosGreen,
          title: const Text("Available Pickups"),
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Pickups"),
        backgroundColor: darwcosGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailablePickups,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: _availablePickups.isEmpty
          ? const Center(
              child: Text(
                "No available pickups right now.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availablePickups.length,
              itemBuilder: (context, index) {
                final pickup = _availablePickups[index];
                final date = pickup['scheduled_date'] ?? '';
                final formattedDate = date.isNotEmpty
                    ? DateFormat('yyyy-MM-dd – hh:mm a')
                        .format(DateTime.parse(date))
                    : 'No Date Provided';
                final restaurantName =
                    pickup['restaurant_name'] ?? 'Unknown Restaurant';
                final address = pickup['pickup_address'] ?? 'No Address';
                final wasteType = pickup['waste_type'] ?? 'N/A';
                final weight = pickup['weight_kg'] ?? '0';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront,
                                color: darwcosGreen, size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                restaurantName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text("📍 $address"),
                        Text("🗑️ Waste Type: $wasteType"),
                        Text("⚖️ Weight: ${weight}kg"),
                        Text("🗓 Scheduled: $formattedDate"),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline,
                                color: Colors.white),
                            label: const Text("Accept Pickup"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darwcosGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                _acceptPickup(pickup['id'], address),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
