import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardVoucherScreen extends StatefulWidget {
  const RewardVoucherScreen({super.key});

  @override
  State<RewardVoucherScreen> createState() => _RewardVoucherScreenState();
}

class _RewardVoucherScreenState extends State<RewardVoucherScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  bool _loading = true;
  List<dynamic> _vouchers = [];
  List<dynamic> _filteredVouchers = [];
  String _message = "";

  final TextEditingController _searchController = TextEditingController();

  // Local fallback vouchers (used when API is empty)
  final List<Map<String, dynamic>> fallbackVouchers = [
    {
      "id": 1,
      "name": "₱50 Discount Voucher",
      "description": "Get ₱50 off on your next waste pickup transaction.",
      "points_required": 50,
      "image": "assets/images/50_discount.png",
    },
    {
      "id": 2,
      "name": "₱100 Discount Voucher",
      "description": "Enjoy ₱100 off your total waste collection fee.",
      "points_required": 100,
      "image": "assets/images/100_discount.png",
    },
    {
      "id": 3,
      "name": "Free Trash Bag Roll",
      "description": "Redeem 1 roll of eco-friendly trash bags for free.",
      "points_required": 30,
      "image": "assets/images/trash_bag.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
    _searchController.addListener(_filterVouchers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVouchers() async {
    try {
      final data = await ApiService.getVouchers();
      setState(() {
        _vouchers = (data.isNotEmpty ? data : fallbackVouchers);
        _filteredVouchers = _vouchers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _vouchers = fallbackVouchers;
        _filteredVouchers = fallbackVouchers;
        _loading = false;
        _message = "Error loading vouchers. Showing default list.";
      });
    }
  }

  void _filterVouchers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVouchers = _vouchers.where((voucher) {
        final name = (voucher['name'] ?? '').toLowerCase();
        final desc = (voucher['description'] ?? '').toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    });
  }

  Future<void> _redeemVoucher(int id) async {
    try {
      final msg = await ApiService.redeemVoucher(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: darwcosGreen),
      );
      _loadVouchers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          titleSpacing: 0,
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: darwcosGreen),
          title: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Text(
                  "Available Vouchers",
                  style: TextStyle(
                    color: darwcosGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search vouchers...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : RefreshIndicator(
              onRefresh: _loadVouchers,
              child: _filteredVouchers.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer_outlined,
                                size: 60, color: Colors.black45),
                            SizedBox(height: 10),
                            Text(
                              "No vouchers found.",
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _filteredVouchers.length,
                      itemBuilder: (context, i) {
                        final item = _filteredVouchers[i];
                        return _buildVoucherCard(item);
                      },
                    ),
            ),
    );
  }

  // 🎨 Compact Voucher Card (smaller and left-aligned)
  Widget _buildVoucherCard(dynamic item) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerLeft, // ensures left alignment
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: screenWidth * 0.3, // now the width will actually apply
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 🖼️ Image section
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item['image'] ?? "assets/images/placeholder.png",
                  width: 65,
                  height: 65,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // 📄 Info + Redeem Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? "Voucher",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'] ?? "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _redeemVoucher(item['id']),
                        icon: const Icon(Icons.redeem,
                            color: Colors.white, size: 16),
                        label: Text(
                          "${item['points_required']} pts",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darwcosGreen,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
  }
}
 