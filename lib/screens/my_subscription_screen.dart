// lib/screens/my_subscription_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'subscription_payments_screen.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  static const Color darwcosGreen = Color(0xFF015704);

  Map<String, dynamic>? _sub;
  List<dynamic> _plans = [];
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final sub = await ApiService.getMySubscription();
      final plans = await ApiService.getPlans();
      if (!mounted) return;
      setState(() {
        _sub = sub;
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load: $e")));
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelAutoRenew() async {
    try {
      final msg = await ApiService.cancelAutoRenew();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cancel failed: $e")));
    }
  }

  Future<void> _showPaymentDialog(int planId, String planName) async {
    String? selectedMethod;
    final TextEditingController voucherController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Subscribe to $planName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose your payment method:"),
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              TextField(
                controller: voucherController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Voucher Code (optional)",
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
              style: ElevatedButton.styleFrom(backgroundColor: darwcosGreen),
              onPressed: () async {
                if (selectedMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please select a payment method.")),
                  );
                  return;
                }
                Navigator.pop(context);
                await _subscribe(planId, planName, selectedMethod!,
                    voucherController.text.trim());
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _subscribe(
      int planId, String planName, String method, String voucherCode) async {
    try {
      await ApiService.subscribeToPlan(
        planId: planId,
        method: method,
        voucherCode: voucherCode.isEmpty ? null : voucherCode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Subscribed to $planName successfully!")),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Subscribe failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "My Subscription",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: darwcosGreen),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : RefreshIndicator(
              color: darwcosGreen,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_sub == null) _buildNoSubscriptionView(),
                    if (_sub != null) _buildSubscriptionCard(),
                    if (_sub != null) _buildPaymentHistoryCard(),
                    const SizedBox(height: 30),
                    _buildAvailablePlansSection(),
                    const SizedBox(height: 40),
                    const Center(
                      child: Text(
                        "D.A.R.W.C.O.S",
                        style: TextStyle(
                          color: darwcosGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // No active subscription
  Widget _buildNoSubscriptionView() {
    return Column(
      children: const [
        Icon(Icons.info_outline, color: Colors.grey, size: 60),
        SizedBox(height: 16),
        Text(
          "No active subscription found.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Active subscription card
  Widget _buildSubscriptionCard() {
    final planName = _sub?['plan_name'] ?? "Unknown Plan";
    final status = _sub?['status'] ?? "unknown";
    final start = _sub?['start_date']?.toString().substring(0, 10) ?? "N/A";
    final end = _sub?['end_date']?.toString().substring(0, 10) ?? "N/A";
    final autoRenew = _sub?['auto_renew'] == true;
    final isActive = _sub?['is_active'] == true;

    // 🖼 Determine the image for the active plan
    String imageAsset = "";
    final lowerName = planName.toLowerCase();
    if (lowerName.contains("basic")) {
      imageAsset = "assets/images/basic.png";
    } else if (lowerName.contains("standard")) {
      imageAsset = "assets/images/premium.png";
    } else if (lowerName.contains("eco")) {
      imageAsset = "assets/images/eco_sub.png";
    } else if (lowerName.contains("premium")) {
      imageAsset = "assets/images/premium.png";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: darwcosGreen.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼 Plan header with image + name
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (imageAsset.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        imageAsset,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (imageAsset.isNotEmpty) const SizedBox(width: 12),
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darwcosGreen,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: darwcosGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? "ACTIVE" : status.toString().toUpperCase(),
                  style: const TextStyle(
                    color: darwcosGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _buildRow("Start Date", start),
          _buildRow("End Date", end),
          const SizedBox(height: 16),

          // 🔁 Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (autoRenew)
                TextButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text(
                    "Cancel Auto-Renew",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: _cancelAutoRenew,
                ),
              TextButton.icon(
                icon: const Icon(Icons.upgrade_rounded, color: darwcosGreen),
                label: const Text(
                  "Change / Renew Plan",
                  style: TextStyle(color: darwcosGreen),
                ),
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Scroll down to choose a new plan."),
                      backgroundColor: darwcosGreen,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Payment History Card
  Widget _buildPaymentHistoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: darwcosGreen),
        title: const Text("Payment History",
            style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SubscriptionPaymentsScreen()),
          );
        },
      ),
    );
  }

  // Available plans section
  Widget _buildAvailablePlansSection() {
    final currentPlanName =
        _sub?['plan_name']?.toString().toLowerCase() ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Available Plans",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darwcosGreen,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _plans
                .where((plan) {
                  final displayName =
                      plan['display_name']?.toString().toLowerCase() ??
                          plan['name'].toString().toLowerCase();
                  return !currentPlanName.contains(displayName);
                })
                .map((plan) => _buildPlanCard(plan))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['display_name'] ?? plan['name'];
    final price = plan['price']?.toString() ?? '0';
    final duration = plan['duration_days']?.toString() ?? '0';
    final desc = plan['description'] ?? '';

    // 🖼 Choose local image asset based on plan name
    String imageAsset = "";
    final lowerName = name.toString().toLowerCase();

    if (lowerName.contains("premium") || lowerName.contains("standard")) {
      imageAsset = "assets/images/premium.png"; // Standard & Premium → premium.png
    } else if (lowerName.contains("eco")) {
      imageAsset = "assets/images/eco_sub.png"; // Eco → eco_sub.png
    } else if (lowerName.contains("basic")) {
      imageAsset = "assets/images/basic.png"; // Basic → basic.png
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageAsset.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imageAsset,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              if (imageAsset.isNotEmpty) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₱$price • $duration days",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      softWrap: true,
                      style: const TextStyle(color: Colors.black54, height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => _showPaymentDialog(plan['id'], name),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darwcosGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 14,
                        ),
                      ),
                      child: const Text(
                        "Choose Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
