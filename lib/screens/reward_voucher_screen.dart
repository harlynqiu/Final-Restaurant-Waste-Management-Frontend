import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/voucher_card.dart'; // ✅ new shared widget

class RewardVoucherScreen extends StatefulWidget {
  const RewardVoucherScreen({super.key});

  @override
  State<RewardVoucherScreen> createState() => _RewardVoucherScreenState();
}

class _RewardVoucherScreenState extends State<RewardVoucherScreen> {
  static const Color darwcosGreen = Color(0xFF015704);
  bool _loading = true;
  List<dynamic> _vouchers = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  // ✅ Load vouchers from API
  Future<void> _loadVouchers() async {
    try {
      final data = await ApiService.getVouchers();
      setState(() {
        _vouchers = data;
        _loading = false;
        _error = "";
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load vouchers: $e";
        _loading = false;
      });
    }
  }

  // ✅ Redeem voucher via API
  Future<void> _redeemVoucher(int voucherId) async {
    try {
      final success = await ApiService.redeemVoucher(voucherId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Voucher redeemed successfully! 🎉"),
            backgroundColor: darwcosGreen,
          ),
        );
        _loadVouchers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to redeem voucher."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text(
          "Reward Vouchers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF015704),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF015704)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : _error.isNotEmpty
              ? Center(
                  child: Text(_error,
                      style: const TextStyle(color: Colors.red, fontSize: 16)),
                )
              : _vouchers.isEmpty
                  ? const Center(
                      child: Text(
                        "No vouchers available yet.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : RefreshIndicator(
                      color: darwcosGreen,
                      onRefresh: _loadVouchers,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🌿 HEADER CARD
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.asset(
                                        "assets/images/rewards.png",
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Collect & Redeem",
                                            style: TextStyle(
                                              color: Color(0xFF015704),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            "Earn eco-points and redeem rewards for your sustainable actions.",
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 15,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              const Padding(
                                padding: EdgeInsets.only(left: 8.0, bottom: 8),
                                child: Text(
                                  "Available Vouchers",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF015704),
                                  ),
                                ),
                              ),

                              // 🎟️ VOUCHER LIST
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _vouchers.length,
                                itemBuilder: (context, index) {
                                  final voucher = _vouchers[index];
                                  final name = voucher['name'] ?? 'Voucher';
                                  final description =
                                      voucher['description'] ??
                                          'No description available.';
                                  final points =
                                      voucher['points_required'] ?? 0;
                                  final id = voucher['id'] ?? 0;
                                  final imageUrl = voucher['image'] ?? '';

                                  return VoucherCard(
                                    name: name,
                                    description: description,
                                    points: points,
                                    imageUrl: imageUrl,
                                    themeColor: darwcosGreen,
                                    showButton: true,
                                    onRedeem: () => _redeemVoucher(id),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
