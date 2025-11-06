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

  // ✅ Build driver card (clickable)
  Widget _pickupCard(Map<String, dynamic> p) {
    final id = p["id"];
    final statusRaw = p["status"].toString().toUpperCase();

    final address = p["pickup_address"] ?? "No Address";
    final wasteType = p["waste_type"] ?? "-";
    final weight = p["weight_kg"].toString();
    final date = _formatDate(p["scheduled_date"] ?? p["created_at"]);

    // ✅ Driver always sees "IN PROGRESS" unless completed
    Color badgeColor;
    String badgeText;

    if (statusRaw == "COMPLETED") {
      badgeColor = Colors.green;
      badgeText = "COMPLETED";
    } else {
      badgeColor = Colors.orange;
      badgeText = "IN PROGRESS";
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          // ✅ Open detail screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PickupDetailScreen(pickup: p),
            ),
          );

          // ✅ If detail screen completes → refresh list
          if (result is Map && result['refresh'] == true) {
            _loadPickups();
          }
        },
        child: Card(
          elevation: 4,
          color: Colors.white,
          shadowColor: darwcosGreen.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ Address
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

                const SizedBox(height: 8),

                // ✅ Waste + Weight
                Text(
                  "🗑 $wasteType   •   ⚖ $weight kg",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),

                // ✅ Date
                Text(
                  "📅 $date",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Build horizontal section
  Widget _section(String title, List<dynamic> items, String icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(icon, width: 30),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darwcosGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (ctx, i) => _pickupCard(items[i]),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final inProgress = _pickups
        .where((p) =>
            p["status"].toString().toUpperCase() == "IN_PROGRESS" ||
            p["status"].toString().toUpperCase() == "ACCEPTED")
        .toList();

    final completed = _pickups
        .where((p) =>
            p["status"].toString().toUpperCase() == "COMPLETED")
        .toList();

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
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16),
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
