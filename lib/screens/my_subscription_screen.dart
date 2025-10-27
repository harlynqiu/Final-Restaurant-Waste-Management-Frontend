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
  String _message = "";

  @override
  void initState() {
    super.initState();
    _loadSub();
  }

  Future<void> _loadSub() async {
    try {
      final data = await ApiService.getMySubscription();
      setState(() {
        _sub = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _message = "Failed to load subscription.";
        _loading = false;
      });
    }
  }

  Future<void> _cancelAutoRenew() async {
    try {
      final msg = await ApiService.cancelAutoRenew();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _loadSub();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cancel failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
        return const Center(child: CircularProgressIndicator());
    }

    // No active subscription yet
    if (_sub == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.subscriptions, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                "No active subscription",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose a plan to activate your waste pickup service.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionPlansScreen()),
                  );
                  _loadSub();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("View Plans"),
              ),
            ],
          ),
        ),
      );
    }

    final planName = _sub?['plan_name'] ?? "Unknown Plan";
    final status = _sub?['status'] ?? "unknown";
    final start = _sub?['start_date']?.toString().substring(0, 10) ?? "-";
    final end = _sub?['end_date']?.toString().substring(0, 10) ?? "-";
    final autoRenew = _sub?['auto_renew'] == true;
    final isActive = _sub?['is_active'] == true;

    return RefreshIndicator(
      onRefresh: _loadSub,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 48),
                  const SizedBox(height: 10),
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActive ? "Status: ACTIVE" : "Status: $status".toUpperCase(),
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Start: $start"),
                  Text("Ends:  $end"),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (autoRenew)
                        OutlinedButton.icon(
                          onPressed: _cancelAutoRenew,
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            "Cancel Auto-Renew",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Let them pick a new plan to "renew"/switch
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SubscriptionPlansScreen()),
                          );
                          _loadSub();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.autorenew),
                        label: const Text("Change / Renew Plan"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.green),
            title: const Text("Payment History"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SubscriptionPaymentsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
