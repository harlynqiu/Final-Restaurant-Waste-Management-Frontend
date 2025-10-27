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
  bool _loading = true;
  List<dynamic> _redemptions = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadRedemptions();
  }

  Future<void> _loadRedemptions() async {
    try {
      final prefsData = await ApiService.getRewardRedemptions();
      setState(() {
        _redemptions = prefsData;
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
      return Scaffold(
        appBar: AppBar(
          title: Text("Redemption History"),
          backgroundColor: Colors.green,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Redemption History"),
          backgroundColor: Colors.green,
        ),
        body: Center(child: Text("Error: $_error")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Redemption History"),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRedemptions,
        child: _redemptions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No redemptions yet."),
                ),
              )
            : ListView.builder(
                itemCount: _redemptions.length,
                itemBuilder: (context, index) {
                  final item = _redemptions[index];
                  final voucher = item['voucher'] ?? {};
                  final isUsed = item['is_used'] ?? false;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.card_giftcard,
                          color: Colors.green, size: 30),
                      title: Text(voucher['name'] ?? "Voucher"),
                      subtitle: Text(
                        "Redeemed: ${item['redeemed_at'].toString().substring(0, 16)}\n"
                        "Points used: ${voucher['points_required'] ?? '-'} pts",
                      ),
                      trailing: Chip(
                        backgroundColor:
                            isUsed ? Colors.grey : Colors.green.shade100,
                        label: Text(
                          isUsed ? "Used" : "Unused",
                          style: TextStyle(
                            color: isUsed ? Colors.grey.shade800 : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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
