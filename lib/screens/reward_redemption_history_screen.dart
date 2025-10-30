import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardRedemptionHistoryScreen extends StatefulWidget {
  const RewardRedemptionHistoryScreen({super.key});

  @override
  State<RewardRedemptionHistoryScreen> createState() =>
      _RewardRedemptionHistoryScreenState();
}

class _RewardRedemptionHistoryScreenState
    extends State<RewardRedemptionHistoryScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<dynamic> _redemptions = [];
  List<dynamic> _filteredRedemptions = [];
  String _error = "";
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterList);
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getRewardRedemptions();
      final pts = await ApiService.getRewardPoints();
      setState(() {
        _redemptions = data;
        _filteredRedemptions = data;
        _points = pts['points'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRedemptions = _redemptions.where((item) {
        final voucher = item['voucher'] ?? {};
        final name = (voucher['name'] ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------- CARD UI --------------------------
  Widget _buildRedemptionCard(dynamic item) {
    final voucher = item['voucher'] ?? {};
    final isUsed = item['is_used'] ?? false;
    final name = voucher['name'] ?? "Voucher";
    final points = voucher['points_required'] ?? 0;
    final date = item['redeemed_at']?.toString().substring(0, 16) ?? "";

    return Card(
      elevation: 3,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: darwcosGreen.withOpacity(0.1),
              child: const Icon(Icons.card_giftcard,
                  color: darwcosGreen, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Redeemed: $date",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    "Points Used: $points pts",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isUsed
                    ? Colors.grey.shade200
                    : darwcosGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUsed ? "Used" : "Unused",
                style: TextStyle(
                  color: isUsed ? Colors.grey : darwcosGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------- UI --------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ---------- HEADER ----------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          titleSpacing: 0,
          automaticallyImplyLeading: true,
          title: Row(
            children: [
              const Text(
                "Redemption History",
                style: TextStyle(
                  color: darwcosGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search voucher...",
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
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
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: darwcosGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _loading ? "..." : "$_points pts",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      // ---------- BODY ----------
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: _error.isNotEmpty
                    ? Center(
                        child: Text(
                          "Error: $_error",
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : _filteredRedemptions.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long,
                                      color: Colors.grey, size: 70),
                                  SizedBox(height: 10),
                                  Text(
                                    "No redemptions yet.",
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final item in _filteredRedemptions)
                                _buildRedemptionCard(item),
                              const SizedBox(height: 40),
                              Image.asset(
                                "assets/images/black_philippine_eagle.png",
                                height: 40,
                              ),
                            ],
                          ),
              ),
            ),
    );
  }
}
