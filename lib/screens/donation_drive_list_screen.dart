import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'donation_form_screen.dart';
import 'my_donations_screen.dart';

class DonationDriveListScreen extends StatefulWidget {
  const DonationDriveListScreen({super.key});

  @override
  State<DonationDriveListScreen> createState() =>
      _DonationDriveListScreenState();
}

class _DonationDriveListScreenState extends State<DonationDriveListScreen> {
  bool _loading = true;
  List<dynamic> _drives = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadDrives();
  }

  Future<void> _loadDrives() async {
    try {
      final data = await ApiService.getDonationDrives();
      setState(() {
        _drives = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load donation drives";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text("Donation Drives"), backgroundColor: Colors.green),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Donation Drives"), backgroundColor: Colors.green),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Donation Drives"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "My Donations",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyDonationsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDrives,
        child: ListView.builder(
          itemCount: _drives.length,
          itemBuilder: (context, index) {
            final drive = _drives[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 3,
              child: ListTile(
                title: Text(
                  drive['title'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
                subtitle: Text(
                    "${drive['description']}\nTarget: ${drive['target_item']}"),
                isThreeLine: true,
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DonationFormScreen(drive: drive),
                      ),
                    );
                  },
                  child: const Text("Donate"),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
