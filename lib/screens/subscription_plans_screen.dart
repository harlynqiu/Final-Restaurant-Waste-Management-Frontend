import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _loading = true;
  List<dynamic> _plans = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final data = await ApiService.getPlans();
      setState(() {
        _plans = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load plans";
        _loading = false;
      });
    }
  }

  // 🟢 Payment selection dialog
Future<void> _showPaymentDialog(int planId, String planName) async {
  String? selectedMethod;
  final TextEditingController voucherController = TextEditingController();

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Subscribe to $planName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose your payment method:"),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Payment Method",
              ),
              items: const [
                DropdownMenuItem(value: "gcash", child: Text("GCash")),
                DropdownMenuItem(value: "card", child: Text("Card")),
                DropdownMenuItem(value: "bank", child: Text("Bank Transfer")),
                DropdownMenuItem(value: "cash", child: Text("Cash")),
              ],
              onChanged: (val) => selectedMethod = val,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: voucherController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Voucher Code (optional)",
                hintText: "Enter code here",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (selectedMethod == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please select a payment method.")),
                );
                return;
              }
              Navigator.pop(context); // close dialog
              _subscribe(
                planId,
                planName,
                selectedMethod!,
                voucherController.text.trim(),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      );
    },
  );
}

  // 🧾 Subscription + receipt
  Future<void> _subscribe(
    int planId,
    String planName,
    String method,
    String voucherCode,
  ) async {
    try {
      final result = await ApiService.subscribeToPlan(
        planId: planId,
        method: method,
        voucherCode: voucherCode.isEmpty ? null : voucherCode,
      );

      if (!mounted) return;

      final subscription = result["subscription"];
      final discount = subscription?["discount_applied"] ?? 0;
      final total = subscription?["final_amount"] ?? subscription?["plan_price"];
      final endDate = subscription?["end_date"]?.toString().substring(0, 10) ?? "-";

      await _showReceiptDialog(
        planName: planName,
        method: method,
        price: total,
        endDate: endDate,
        discount: discount,
        voucherCode: voucherCode,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Subscribe failed: $e")));
    }
  }

  // 🎟️ Receipt dialog after successful subscription
  Future<void> _showReceiptDialog({
    required String planName,
    required String method,
    required dynamic price,
    required String endDate,
    double discount = 0,
    String? voucherCode,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Colors.green, size: 60),
                const SizedBox(height: 10),
                const Text(
                  "Subscription Successful!",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReceiptRow("Plan", planName),
                      _buildReceiptRow("Payment Method", method.toUpperCase()),
                      if (voucherCode != null && voucherCode.isNotEmpty)
                        _buildReceiptRow("Voucher", voucherCode),
                      if (discount > 0)
                        _buildReceiptRow("Discount", "- ₱$discount"),
                      _buildReceiptRow("Total", "₱$price"),
                      _buildReceiptRow("Valid Until", endDate),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Done"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Plans"),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Plans"),
          backgroundColor: Colors.green,
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose a Plan"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];

          final displayName = plan['display_name'] ?? plan['name'];
          final price = plan['price']?.toString() ?? '';
          final duration = plan['duration_days']?.toString() ?? '';
          final desc = plan['description'] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text("₱$price for $duration days",
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(
                    desc.isEmpty ? "No description provided." : desc,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          _showPaymentDialog(plan['id'], displayName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text("Choose this plan"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
