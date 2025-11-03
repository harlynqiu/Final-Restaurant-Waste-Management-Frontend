import 'package:flutter/material.dart';
import '../services/api_service.dart';

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

  Future<void> _loadVouchers() async {
    try {
      final data = await ApiService.getVouchers();
      setState(() {
        _vouchers = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load vouchers: $e";
        _loading = false;
      });
    }
  }

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

  // 🖼️ Local asset picker based on voucher name
  String _getVoucherImage(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("50")) return "assets/images/50_discount.png";
    if (lower.contains("100")) return "assets/images/100_discount.png";
    if (lower.contains("bag")) return "assets/images/free_bag.png";
    if (lower.contains("trash")) return "assets/images/trash_voucher.png";
    return "assets/images/default_voucher.png";
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                  ),
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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🌿 HEADER / BANNER SECTION
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 🎁 Image on the LEFT
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        "assets/images/rewards.png",
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // 🌱 Text on the RIGHT
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            "Collect & Redeem",
                                            style: TextStyle(
                                              color: Color(0xFF015704),
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            "Earn eco-points and redeem rewards for your sustainable actions.",
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

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

                              // 🎟️ VOUCHER CARDS
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _vouchers.length,
                                itemBuilder: (context, index) {
                                  final voucher = _vouchers[index];
                                  final name = voucher['name'] ?? 'Voucher';
                                  final description =
                                      voucher['description'] ??
                                          'No description';
                                  final points =
                                      voucher['points_required'] ?? 0;
                                  final id = voucher['id'] ?? 0;
                                  final imageAsset = _getVoucherImage(name);

                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.42, // ✅ smaller card width
                                      margin:
                                          const EdgeInsets.only(bottom: 14),
                                      child: Card(
                                        elevation: 2,
                                        shadowColor:
                                            darwcosGreen.withOpacity(0.15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  imageAsset,
                                                  height: 55,
                                                  width: 55,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 17, // ⬆️ bigger font
                                                        color: darwcosGreen,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      description,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 15, // ⬆️ bigger
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          "$points pts",
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                Colors.black87,
                                                            fontSize: 15, // ⬆️ bigger
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              _redeemVoucher(
                                                                  id),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                darwcosGreen,
                                                            foregroundColor:
                                                                Colors.white,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 14,
                                                              vertical: 6,
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            "Redeem",
                                                            style: TextStyle(
                                                                fontSize:
                                                                    14), // ⬆️ bigger
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
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
