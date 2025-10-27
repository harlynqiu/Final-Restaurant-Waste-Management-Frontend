import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrashPickupScreen extends StatefulWidget {
  const TrashPickupScreen({super.key});

  @override
  State<TrashPickupScreen> createState() => _TrashPickupScreenState();
}

class _TrashPickupScreenState extends State<TrashPickupScreen> {
  bool _loading = true;
  List<dynamic> _pickups = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadPickups();
  }

  Future<void> _loadPickups() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getTrashPickups();
      setState(() {
        _pickups = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(child: Text("Error: $_error"));
    }

    return RefreshIndicator(
      onRefresh: _loadPickups,
      child: _pickups.isEmpty
          ? const Center(child: Text("No pickups yet. Pull down to refresh."))
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _pickups.length,
              itemBuilder: (context, index) {
                final item = _pickups[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.recycling, color: Colors.green),
                    title: Text(item['restaurant_name'] ?? "Unknown"),
                    subtitle: Text(
                      "Waste: ${item['waste_type']} • ${item['weight_kg']}kg\nStatus: ${item['status']}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
