import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'subscription_plans_screen.dart';
import 'subscription_payments_screen.dart';

class MySubscriptionScreen extends StatefulWidget {
  const MySubscriptionScreen({super.key});

  @override
  State<MySubscriptionScreen> createState() => _MySubscriptionScreenState();
}

class _MySubscriptionScreenState extends State<MySubscriptionScreen> {
  Map<String, dynamic>? _sub;
  bool _loading = true;

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  @override
  void initState() {
    super.initState();
    _loadSub();
  }

  Future<void> _loadSub() async {
    try {
      final data = await ApiService.getMySubscription();
      if (!mounted) return;
      setState(() {
        _sub = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load: $e")),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelAutoRenew() async {
    try {
      final msg = await ApiService.cancelAutoRenew();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      _loadSub();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cancel failed: $e")));
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
              onRefresh: _loadSub,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    // 🟩 No subscription yet
                    if (_sub == null) _buildNoSubscriptionView(),

                    // 🟩 Active subscription card
                    if (_sub != null) _buildSubscriptionCard(),

                    // 💳 Payment history section
                    if (_sub != null) _buildPaymentHistoryCard(),

                    const SizedBox(height: 30),

                    // 💡 Footer branding
                    const Text(
                      "D.A.R.W.C.O.S",
                      style: TextStyle(
                        color: darwcosGreen,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // 🧩 No active subscription
  Widget _buildNoSubscriptionView() {
    return Column(
      children: [
        const Icon(Icons.info_outline, color: Colors.grey, size: 60),
        const SizedBox(height: 16),
        const Text(
          "No active subscription found.",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
            );
            _loadSub();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: darwcosGreen,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          label: const Text(
            "View Available Plans",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // 🧩 Active subscription details
  Widget _buildSubscriptionCard() {
    final planName = _sub?['plan_name'] ?? "Unknown Plan";
    final status = _sub?['status'] ?? "unknown";
    final start = _sub?['start_date']?.toString().substring(0, 10) ?? "N/A";
    final end = _sub?['end_date']?.toString().substring(0, 10) ?? "N/A";
    final autoRenew = _sub?['auto_renew'] == true;
    final isActive = _sub?['is_active'] == true;

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darwcosGreen,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: darwcosGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive
                        ? "ACTIVE"
                        : status.toString().toUpperCase(),
                    style: const TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _sub?["description"] ??
                  "Subscription plan details not available.",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Start Date:",
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
                Text(
                  start,
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("End Date:",
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
                Text(
                  end,
                  style: const TextStyle(
                      color: Colors.black87, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🔁 Buttons for renew / cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (autoRenew)
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      "Cancel Auto-Renew",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _cancelAutoRenew,
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.upgrade_rounded, color: darwcosGreen),
                  label: const Text(
                    "Change / Renew Plan",
                    style: TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubscriptionPlansScreen()),
                    );
                    _loadSub();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 💳 Payment History Card
  Widget _buildPaymentHistoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: darwcosGreen),
        title: const Text(
          "Payment History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
}
