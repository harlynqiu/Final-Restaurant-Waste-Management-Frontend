import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'donation_drive_list_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
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
        _error = "Failed to load donations: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darwcosGreen,
        elevation: 2,
        title: const Text(
          "My Donations",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volunteer_activism),
            tooltip: "Active Donation Drives",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationDriveListScreen()),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: darwcosGreen),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : _donations.isEmpty
                  ? const Center(
                      child: Text(
                        "You haven’t made any donations yet.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : RefreshIndicator(
                      color: darwcosGreen,
                      onRefresh: _loadDonations,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _donations.length,
                        itemBuilder: (context, index) {
                          final d = _donations[index];
                          final driveTitle = d['drive_title'] ?? "Donation Drive";
                          final item = d['donated_item'] ?? "Unknown item";
                          final qty = d['quantity']?.toString() ?? "0";
                          final status = d['status'] ?? "Pending";
                          final date = d['created_at']?.toString().substring(0, 10) ?? "";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: darwcosGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.recycling_rounded,
                                  color: darwcosGreen,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                driveTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darwcosGreen,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$item — $qty kg",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Status: $status",
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color: status.toLowerCase() == "completed"
                                            ? Colors.green[700]
                                            : Colors.orange[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (date.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          "Date: $date",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
