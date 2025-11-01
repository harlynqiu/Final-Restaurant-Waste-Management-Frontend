// lib/screens/subscription_plans_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  // 🔠 Helper: Capitalize each word properly
  String _capitalizeEachWord(String text) {
    return text
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  bool _loading = true;
  List<dynamic> _plans = [];
  Map<String, dynamic>? _mySubscription;
  String _error = "";

  static const Color darwcosGreen = Color(0xFF015704);

  // Local fallback plans (used if API fails)
  final List<Map<String, dynamic>> fallbackPlans = [
    {
      "id": 1,
      "name": "Basic Plan",
      "display_name": "Basic Plan",
      "price": 299,
      "duration_days": 30,
      "description":
          "Ideal for small restaurants or cafés. Includes up to 8 scheduled waste pickups per month and access to basic waste segregation tips.",
      "icon": Icons.recycling,
    },
    {
      "id": 2,
      "name": "Standard Plan",
      "display_name": "Standard Plan",
      "price": 799,
      "duration_days": 90,
      "description":
          "Perfect for growing establishments. Enjoy up to 25 waste pickups per quarter, faster driver response times, and priority scheduling.",
      "icon": Icons.upgrade,
    },
    {
      "id": 3,
      "name": "Eco+ Plan",
      "display_name": "Eco+ Plan",
      "price": 999,
      "duration_days": 90,
      "description":
          "A sustainability-focused plan. Earn extra reward points for eco-friendly waste disposal and contributions to donation drives.",
      "icon": Icons.eco,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final plans = await ApiService.getPlans();
      final sub = await ApiService.getMySubscription();
      setState(() {
        _plans = plans.isNotEmpty ? plans : fallbackPlans;
        _mySubscription = sub;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _plans = fallbackPlans;
        _mySubscription = null;
        _loading = false;
        _error = "Failed to load plans. Showing default data.";
      });
    }
  }

  // ------------------------------------------------------------
  // 🧾 Subscription Flow
  // ------------------------------------------------------------
  Future<void> _showPaymentDialog(int planId, String planName) async {
    String? selectedMethod;
    final TextEditingController voucherController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Subscribe to ${_capitalizeEachWord(planName)}"),
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
              style:
                  ElevatedButton.styleFrom(backgroundColor: darwcosGreen),
              onPressed: () {
                if (selectedMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please select a payment method.")),
                  );
                  return;
                }
                Navigator.pop(context);
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
      final total =
          subscription?["final_amount"] ?? subscription?["plan_price"];
      final endDate =
          subscription?["end_date"]?.toString().substring(0, 10) ?? "-";

      await _showReceiptDialog(
        planName: _capitalizeEachWord(planName),
        method: method,
        price: total,
        endDate: endDate,
        discount: discount,
        voucherCode: voucherCode,
      );
      _loadAllData(); // refresh after success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Subscribe failed: $e")));
    }
  }

  // ------------------------------------------------------------
  // 🎟️ Receipt Dialog
  // ------------------------------------------------------------
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
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Dialog(
              backgroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: darwcosGreen.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset("assets/images/payment.png"),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Subscription Activated!",
                      style: TextStyle(
                        color: darwcosGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "You’re now part of the D.A.R.W.C.O.S. clean movement 🌱",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13.5,
                          height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: darwcosGreen.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReceiptRow("Plan", planName),
                          _buildReceiptRow("Payment", method.toUpperCase()),
                          if (voucherCode != null && voucherCode.isNotEmpty)
                            _buildReceiptRow("Voucher", voucherCode),
                          if (discount > 0)
                            _buildReceiptRow("Discount", "- ₱$discount"),
                          const Divider(height: 16),
                          _buildReceiptRow("Total Paid", "₱$price"),
                          _buildReceiptRow("Valid Until", endDate),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darwcosGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_rounded,
                            color: Colors.white),
                        label: const Text(
                          "Got it",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'RobotoMono')),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 🖥️ UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Subscription Plans"),
          backgroundColor: Colors.white,
          foregroundColor: darwcosGreen,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentPlanName = _mySubscription?["plan_name"];
    final endDate =
        _mySubscription?["end_date"]?.toString().substring(0, 10);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Subscription Plans"),
        backgroundColor: Colors.white,
        foregroundColor: darwcosGreen,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: _plans.map((plan) {
                final displayName =
                    _capitalizeEachWord(plan['display_name'] ?? plan['name']);
                final price = plan['price']?.toString() ?? '';
                final duration = plan['duration_days']?.toString() ?? '';
                final desc = plan['description'] ?? '';
                final icon = plan['icon'] as IconData?;

                final isActive = currentPlanName != null &&
                    currentPlanName
                        .toString()
                        .toLowerCase()
                        .contains(displayName
                            .toString()
                            .toLowerCase()
                            .split(' ')
                            .first);

                return Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  darwcosGreen.withOpacity(0.1),
                              child: Icon(icon ?? Icons.star,
                                  color: darwcosGreen, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: darwcosGreen),
                                      ),
                                      if (isActive)
                                        Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
                                          decoration: BoxDecoration(
                                            color: darwcosGreen
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(8),
                                          ),
                                          child: const Text(
                                            "ACTIVE",
                                            style: TextStyle(
                                                color:
                                                    darwcosGreen,
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    "₱$price • $duration days",
                                    style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight:
                                            FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          desc,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        if (!isActive)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showPaymentDialog(
                                  plan['id'], displayName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darwcosGreen,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            12)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                              child: const Text(
                                "Choose this Plan",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold),
                              ),
                            ),
                          )
                        else
                          Text(
                            "Valid until: $endDate",
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontStyle:
                                    FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
