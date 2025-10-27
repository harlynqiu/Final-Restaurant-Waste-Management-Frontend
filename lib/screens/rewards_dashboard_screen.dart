import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'reward_voucher_screen.dart'; // 👈 for redeeming vouchers
import 'reward_redemption_history_screen.dart'; // 👈 for redemption history (to be added next)

class RewardsDashboardScreen extends StatefulWidget {
  const RewardsDashboardScreen({super.key});

  @override
  State<RewardsDashboardScreen> createState() =>
      _RewardsDashboardScreenState();
}

class _RewardsDashboardScreenState extends State<RewardsDashboardScreen> {
  int _points = 0;
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final pointsData = await ApiService.getRewardPoints();
      final transactionsData = await ApiService.getRewardTransactions();
      setState(() {
        _points = pointsData['points'] ?? 0;
        _transactions = transactionsData;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _getTransactionColor(String type) {
    if (type == "redeem") return Colors.red;
    return Colors.green;
  }

  IconData _getTransactionIcon(String type) {
    if (type == "redeem") return Icons.remove_circle;
    return Icons.add_circle;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadRewards,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 25),

          // --------------------------------------------
          // 🏆 POINTS SUMMARY CARD
          // --------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.green.shade50,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.green, size: 70),
                    const SizedBox(height: 10),
                    Text(
                      "$_points Points",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Earn points for every completed pickup!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RewardVoucherScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                          icon: const Icon(Icons.card_giftcard),
                          label: const Text("Redeem Points"),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const RewardRedemptionHistoryScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                          icon: const Icon(Icons.history),
                          label: const Text("View History"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),
          const Divider(),

          // --------------------------------------------
          // 🧾 TRANSACTION HISTORY
          // --------------------------------------------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Transaction History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          if (_transactions.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("No transactions yet"),
            )),

          ..._transactions.map((t) {
            final type = t['transaction_type'] ?? 'earn';
            final color = _getTransactionColor(type);
            final icon = _getTransactionIcon(type);
            final prefix = type == "redeem" ? "-" : "+";
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text(t['description'] ?? "Transaction"),
                subtitle: Text(
                    "Date: ${t['created_at'].toString().substring(0, 16)}"),
                trailing: Text(
                  "$prefix${t['points']} pts",
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
