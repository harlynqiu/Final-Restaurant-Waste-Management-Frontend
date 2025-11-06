// lib/screens/trash_pickup_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'trash_pickup_form_screen.dart';
import 'pickup_detail_screen.dart';

class TrashPickupScreen extends StatefulWidget {
  const TrashPickupScreen({super.key});

  @override
  State<TrashPickupScreen> createState() => _TrashPickupScreenState();
}

class _TrashPickupScreenState extends State<TrashPickupScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  List<dynamic> pickups = [];
  bool _isLoading = true;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  // ✅ Fetch pickups + reward points
  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);

    try {
      final pts = await ApiService.getUserPoints();
      final list = await ApiService.getTrashPickups();

      setState(() {
        _points = pts;
        pickups = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Navigate to detail + refresh on return
  void _openDetail(Map<String, dynamic> pickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PickupDetailScreen(pickup: pickup)),
    );

    if (result is Map && result['refresh'] == true) {
      _fetchAll();
    }
  }

  // ✅ New pickup
  void _addPickup() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrashPickupFormScreen()),
    );
    if (created == true) _fetchAll();
  }

  // ✅ Status Colors
  Color _statusColor(String s) {
    final status = s.toUpperCase();
    return {
      "PENDING": Colors.orangeAccent,
      "ACCEPTED": Colors.orangeAccent, // treated same as pending
      "IN_PROGRESS": Colors.blueAccent,
      "COMPLETED": Colors.green,
      "CANCELLED": Colors.redAccent,
    }[status] ?? Colors.grey;
  }

  // ✅ Status Icon
  IconData _statusIcon(String s) {
    final status = s.toUpperCase();
    return {
      "PENDING": Icons.schedule,
      "ACCEPTED": Icons.schedule, // icon same as pending
      "IN_PROGRESS": Icons.play_circle_outline,
      "COMPLETED": Icons.check_circle_outline,
      "CANCELLED": Icons.cancel_outlined,
    }[status] ?? Icons.help_outline;
  }

  // ✅ Format date
  String _formatDate(dynamic dateString) {
    try {
      final parsed = DateTime.parse(dateString.toString());
      return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return "No schedule";
    }
  }

  // ✅ Build pickup card (updated accepted → pending)
  Widget _buildPickupCard(Map<String, dynamic> p) {
    final rawStatus = p["status"]?.toString().toUpperCase() ?? "UNKNOWN";

    // ✅ Convert "ACCEPTED" → "PENDING" for UI only
    final status = rawStatus == "ACCEPTED" ? "PENDING" : rawStatus;

    final color = _statusColor(status);

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetail(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Icon box
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(status),
                  color: color,
                  size: 40,
                ),
              ),
              const SizedBox(width: 14),

              // ✅ Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Address or Restaurant Name
                    Text(
                      p["pickup_address"] ??
                          p["restaurant_name"] ??
                          "No address provided",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // ✅ Show restaurant name separately
                    if (p["restaurant_name"] != null)
                      Text(
                        p["restaurant_name"],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    const SizedBox(height: 6),

                    // ✅ Scheduled date
                    Text(
                      _formatDate(p["scheduled_date"]),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ✅ Waste type + weight
                    Row(
                      children: [
                        // Waste type
                        if (p["waste_type"] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: darwcosGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${p["waste_type"]}"
                                      .substring(0, 1)
                                      .toUpperCase() +
                                  "${p["waste_type"]}".substring(1),
                              style: const TextStyle(
                                color: darwcosGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        const SizedBox(width: 8),

                        // Weight
                        if (p["weight_kg"] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${p["weight_kg"]} kg",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ✅ Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll("_", " "),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Filters (updated to include accepted in active)
  List<dynamic> get _activePickups => pickups.where((p) {
        final s = p["status"]?.toString().toUpperCase() ?? "";
        return s == "PENDING" || s == "ACCEPTED" || s == "IN_PROGRESS";
      }).toList();

  List<dynamic> get _pastPickups => pickups.where((p) {
        final s = p["status"]?.toString().toUpperCase() ?? "";
        return s == "COMPLETED" || s == "CANCELLED";
      }).toList();

  // ✅ Build list
  Widget _buildPickupList(List<dynamic> list, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: list.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              itemCount: list.length,
              itemBuilder: (context, i) => _buildPickupCard(list[i]),
            ),
    );
  }

  // ✅ Main UI
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          iconTheme: const IconThemeData(color: darwcosGreen),
          title: const Text(
            "Trash Pickups",
            style: TextStyle(
              color: darwcosGreen,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Chip(
                label: Text(
                  "$_points pts",
                  style: const TextStyle(
                    color: darwcosGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: darwcosGreen.withOpacity(0.1),
                side: const BorderSide(color: darwcosGreen),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: darwcosGreen,
            labelColor: darwcosGreen,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "New Pickups"),
              Tab(text: "Past Transactions"),
            ],
          ),
        ),

        // ✅ Floating button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addPickup,
          backgroundColor: darwcosGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "New Pickup",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: darwcosGreen),
              )
            : TabBarView(
                children: [
                  _buildPickupList(_activePickups, "No active pickups."),
                  _buildPickupList(_pastPickups, "No past transactions."),
                ],
              ),
      ),
    );
  }
}
