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
      // Fetch from API
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
        _loadVouchers(); // Refresh after redeem
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Vouchers"),
        backgroundColor: darwcosGreen,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _vouchers.isEmpty
                  ? const Center(
                      child: Text(
                        "No vouchers available yet.",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadVouchers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vouchers.length,
                        itemBuilder: (context, index) {
                          final voucher = _vouchers[index];
                          final name = voucher['name'] ?? 'Voucher';
                          final description =
                              voucher['description'] ?? 'No description';
                          final points = voucher['points_required'] ?? 0;
                          final id = voucher['id'] ?? 0;

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.card_giftcard,
                                        color: darwcosGreen, size: 35),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    subtitle: Text(description),
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$points pts",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: darwcosGreen),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _redeemVoucher(id),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: darwcosGreen,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text("Redeem"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
