import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'driver_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DriverPickupsScreen extends StatefulWidget {
  const DriverPickupsScreen({super.key});

  @override
  State<DriverPickupsScreen> createState() => _DriverPickupsScreenState();
}

class _DriverPickupsScreenState extends State<DriverPickupsScreen> {
  bool _loading = true;
  List<dynamic> _pickups = [];
  String _error = "";

  static const Color darwcosGreen = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadPickups(); // ✅ this will call getAssignedPickups()
  }

  Future<void> _loadPickups() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("🔑 Access token: ${prefs.getString('access_token')}"); // 👈 check token first

    try {
      final data = await ApiService.getAssignedPickups();
      setState(() {
        _pickups = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "❌ Failed to load pickups: $e";
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async => _loadPickups();

  // Status color helper
  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "ASSIGNED":
        return Colors.orange;
      case "ON_THE_WAY":
        return Colors.blue;
      case "PICKED_UP":
        return Colors.green;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

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
          title: const Text("Assigned Pickups"),
          backgroundColor: darwcosGreen,
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Pickups"),
        backgroundColor: darwcosGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _pickups.isEmpty
            ? const Center(child: Text("No assigned pickups yet."))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pickups.length,
                itemBuilder: (context, index) {
                  final pickup = _pickups[index];
                  final date = pickup['scheduled_date'] ?? '';
                  final formattedDate = date.isNotEmpty
                      ? DateFormat('yyyy-MM-dd – kk:mm')
                          .format(DateTime.parse(date))
                      : 'No Date';
                  final status = pickup['status'] ?? 'Unknown';
                  final address = pickup['pickup_address'] ?? 'No Address';
                  final wasteType = pickup['waste_type'] ?? 'N/A';
                  final weight = pickup['weight_kg'] ?? '0';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.recycling, color: _statusColor(status)),
                      title: Text(
                        address,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Type: $wasteType"),
                          Text("Weight: ${weight}kg"),
                          Text("Date: $formattedDate"),
                          Text(
                            "Status: $status",
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
