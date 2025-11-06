// lib/screens/driver_pickups_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'pickup_detail_screen.dart';

class DriverPickupsScreen extends StatefulWidget {
  const DriverPickupsScreen({super.key});

  @override
  State<DriverPickupsScreen> createState() => _DriverPickupsScreenState();
}

class _DriverPickupsScreenState extends State<DriverPickupsScreen> {
  static const Color darwcosGreen = Color(0xFF015704);

  bool _loading = true;
  List<dynamic> _pickups = [];

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  Future<void> _loadPickups() async {
    try {
      final data = await ApiService.getAssignedPickups();
      setState(() {
        _pickups = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async => _loadPickups();

  // ✅ Format date
  String _formatDate(dynamic value) {
    try {
      final d = DateTime.parse(value.toString());
      return DateFormat('MMM dd, yyyy • hh:mm a').format(d);
    } catch (_) {
      return "No date";
    }
  }

  // ✅ Status color
  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case "IN_PROGRESS":
        return Colors.orange;
      case "COMPLETED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ✅ Complete pickup
  Future<void> _completePickup(int id) async {
    try {
      final ok = await ApiService.completePickup(id);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pickup Completed!"),
            backgroundColor: darwcosGreen,
          ),
        );
        _loadPickups();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // ✅ Build card
  Widget _pickupCard(Map<String, dynamic> p) {
    final id = p["id"];
    final status = p["status"].toString().toUpperCase();
    final color = _statusColor(status);

    final address = p["pickup_address"] ?? "No Address";
    final wType = p["waste_type"] ?? "-";
    final weight = p["weight_kg"]?.toString() ?? "0";
    final date = _formatDate(p["scheduled_date"] ?? p["created_at"]);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      child: Card(
        elevation: 3,
        color: Colors.white,
        shadowColor: darwcosGreen.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PickupDetailScreen(pickup: p),
              ),
            );
            if (result is Map && result['refresh'] == true) {
              _loadPickups();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status pill
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.map, color: darwcosGreen, size: 20),
                  ],
                ),
                const SizedBox(height: 10),

                // Address
                Text(
                  address,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Waste & Weight
                Text(
                  "🗑 $wType   •   ⚖ $weight kg",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // Date
                Text(
                  "📅 $date",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),

                if (status == "IN_PROGRESS")
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _completePickup(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darwcosGreen,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Complete",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  // ✅ Build horizontal list section
  Widget _section(String title, List<dynamic> items, String icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(icon, width: 32, height: 32),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darwcosGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (ctx, index) => _pickupCard(items[index]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inProgress = _pickups.where((p) =>
        p["status"].toString().toUpperCase() == "IN_PROGRESS").toList();

    final completed = _pickups.where((p) =>
        p["status"].toString().toUpperCase() == "COMPLETED").toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "My Pickups",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: darwcosGreen),
            onPressed: _refresh,
          )
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: darwcosGreen),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section("In Progress", inProgress,
                        "assets/images/in_progress.png"),
                    _section("Completed", completed,
                        "assets/images/complete.png"),

                    if (inProgress.isEmpty && completed.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Text(
                            "No assigned pickups yet.",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 16),
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
