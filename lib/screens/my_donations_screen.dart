import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  bool _loading = true;
  List<dynamic> _donations = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    try {
      final data = await ApiService.getMyDonations();
      setState(() {
        _donations = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load donations";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text("My Donations"), backgroundColor: Colors.green),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Donations"), backgroundColor: Colors.green),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Donations"),
        backgroundColor: Colors.green,
      ),
      body: _donations.isEmpty
          ? const Center(child: Text("No donations yet."))
          : RefreshIndicator(
              onRefresh: _loadDonations,
              child: ListView.builder(
                itemCount: _donations.length,
                itemBuilder: (context, index) {
                  final d = _donations[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ListTile(
                      title: Text(d['drive_title'] ?? "Donation Drive"),
                      subtitle: Text(
                        "${d['donated_item']} — ${d['quantity']} kg\nStatus: ${d['status']}",
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
