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

  // ---------------- FETCH ALL PICKUPS ----------------
  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final pts = await ApiService.getUserPoints();
      final list = await ApiService.getTrashPickupsAuto();
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

  // ---------------- OPEN PICKUP DETAIL ----------------
  void _openDetail(Map<String, dynamic> pickup) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PickupDetailScreen(pickup: pickup),
      ),
    );

    if (result is Map && result['refresh'] == true) {
      _fetchAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pickup updated successfully."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // ---------------- ADD NEW PICKUP ----------------
  void _addPickup() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrashPickupFormScreen(),
      ),
    );
    if (created == true) _fetchAll();
  }

  // ---------------- STATUS COLOR ----------------
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Colors.orangeAccent;
      case "IN_PROGRESS":
        return Colors.blueAccent;
      case "COMPLETED":
        return Colors.green;
      case "CANCELLED":
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  // ---------------- STATUS ICON ----------------
  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case "PENDING":
        return Icons.schedule;
      case "IN_PROGRESS":
        return Icons.play_circle_outline;
      case "COMPLETED":
        return Icons.check_circle_outline;
      case "CANCELLED":
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // ---------------- FORMAT DATE ----------------
  String _formatDate(dynamic dateString) {
    if (dateString == null ||
        dateString.toString().isEmpty ||
        dateString.toString().toLowerCase() == "null") {
      return "No schedule";
    }
    try {
      final parsed = DateTime.parse(dateString.toString());
      return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return "Invalid date";
    }
  }

  // ---------------- BUILD PICKUP CARD ----------------
  Widget _buildPickupCard(Map<String, dynamic> p) {
    final status = p["status"]?.toString().toUpperCase() ?? "UNKNOWN";
    final color = _getStatusColor(status);

    return Card(
      elevation: 3,
      shadowColor: darwcosGreen.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(p),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 🟢 Pickup icon with original colors
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    "assets/images/pickup.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p["pickup_address"] ??
                          p["restaurant_name"] ??
                          "No address provided",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(p["scheduled_date"]),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- FILTERS FOR ACTIVE / PAST ----------------
  List<dynamic> get _activePickups => pickups
      .where((p) =>
          p["status"] == "pending" || p["status"] == "in_progress")
      .toList();

  List<dynamic> get _pastPickups => pickups
      .where((p) =>
          p["status"] == "completed" || p["status"] == "cancelled")
      .toList();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // two tabs
      child: Scaffold(
        backgroundColor: Colors.grey[100],
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
                  // 🟢 TAB 1: ACTIVE PICKUPS
                  _buildPickupList(_activePickups, "No active pickups."),

                  // ⚫ TAB 2: PAST TRANSACTIONS
                  _buildPickupList(_pastPickups, "No past transactions."),
                ],
              ),
      ),
    );
  }

  // ---------------- BUILD LIST FOR EACH TAB ----------------
  Widget _buildPickupList(List<dynamic> list, String emptyMessage) {
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: list.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: list.length,
              itemBuilder: (context, i) => _buildPickupCard(list[i]),
            ),
    );
  }
}
