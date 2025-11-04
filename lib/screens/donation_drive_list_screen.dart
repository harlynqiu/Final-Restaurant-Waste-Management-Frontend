import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'my_donations_screen.dart';

class DonationDriveListScreen extends StatefulWidget {
  const DonationDriveListScreen({super.key});

  @override
  State<DonationDriveListScreen> createState() =>
      _DonationDriveListScreenState();
}

class _DonationDriveListScreenState extends State<DonationDriveListScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
  bool _loading = true;
  List<dynamic> _drives = [];
  String _error = "";

  final List<Map<String, dynamic>> fallbackDrives = [
    {
      "id": 1,
      "title": "Plastic-Free Davao Initiative",
      "description":
          "Join the movement to collect recyclable plastic bottles and containers from local restaurants and households.",
      "target_item": "Plastic bottles and packaging",
      "image": "assets/images/plastic_waste.png",
    },
    {
      "id": 2,
      "title": "Compost for Community Gardens",
      "description":
          "Help reduce food waste by donating compostable materials for use in barangay gardens across Davao City.",
      "target_item": "Organic waste and compostable scraps",
      "image": "assets/images/kitchen_waste.png",
    },
    {
      "id": 3,
      "title": "E-Waste Collection Drive",
      "description":
          "Safely dispose of electronic kitchen tools and appliances for proper recycling and reuse.",
      "target_item": "E-waste (blenders, rice cookers, cables)",
      "image": "assets/images/customer_waste.png",
    },
    {
      "id": 4,
      "title": "Davao Thermo Biotech Corp",
      "description":
          "A pioneering effort to convert biodegradable waste into renewable biothermal energy. Participate by donating kitchen and food waste for sustainable energy production.",
      "target_item": "Biodegradable and kitchen waste",
      "image": "assets/images/davao_thermo_corp.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDrives();
  }

  Future<void> _loadDrives() async {
    try {
      final data = await ApiService.getDonationDrives();
      setState(() {
        _drives = (data.isNotEmpty ? data : fallbackDrives);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _drives = fallbackDrives;
        _error = "Showing default donation drives (offline mode).";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Donation Drives"),
          backgroundColor: Colors.white,
          foregroundColor: darwcosGreen,
          elevation: 2,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: darwcosGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darwcosGreen,
        elevation: 2,
        title: const Text(
          "Active Donation Drives",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
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
        child: ListView(
          children: [
            // 🌿 Gradient Header Card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    darwcosGreen.withOpacity(0.9),
                    const Color(0xFF4CAF50),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        "assets/images/donation.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Give Back to the Community 🌱",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Turn waste into kindness. Join Davao’s active donation drives and help support sustainability, one item at a time.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🧩 Donation Drives List
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _drives.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Text(
                          "No active donation drives available.",
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      ),
                    )
                  : Column(
                      children: _drives.map((drive) {
                        final hasImage = drive['image'] != null &&
                            drive['image'].toString().isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DonationDriveDetailScreen(drive: drive),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasImage)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        drive['image'],
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: darwcosGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.volunteer_activism,
                                        color: darwcosGreen,
                                        size: 32,
                                      ),
                                    ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          drive['title'] ?? 'Unnamed Drive',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: darwcosGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          drive['description'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "🎯 Target: ${drive['target_item'] ?? 'N/A'}",
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------
// 🟢 Donation Drive Detail Screen
// ---------------------------------------------
class DonationDriveDetailScreen extends StatelessWidget {
  final Map<String, dynamic> drive;

  const DonationDriveDetailScreen({super.key, required this.drive});

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  Widget build(BuildContext context) {
    final hasImage =
        drive['image'] != null && drive['image'].toString().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: darwcosGreen,
        elevation: 2,
        title: const Text(
          "Donation Drive Details",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      drive['image'],
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (hasImage) const SizedBox(height: 16),
                Text(
                  drive['title'] ?? 'Unnamed Drive',
                  style: const TextStyle(
                    color: darwcosGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  drive['description'] ?? 'No description provided.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "🎯 Target Item:",
                  style: TextStyle(
                    color: darwcosGreen.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  drive['target_item'] ?? 'N/A',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
