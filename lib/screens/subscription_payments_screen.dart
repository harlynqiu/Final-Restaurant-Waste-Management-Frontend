import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubscriptionPaymentsScreen extends StatefulWidget {
  const SubscriptionPaymentsScreen({super.key});

  @override
  State<SubscriptionPaymentsScreen> createState() =>
      _SubscriptionPaymentsScreenState();
}

class _SubscriptionPaymentsScreenState
    extends State<SubscriptionPaymentsScreen> {
  bool _loading = true;
  List<dynamic> _payments = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      final data = await ApiService.getPaymentHistory();
      setState(() {
        _payments = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load payments";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Payment History"),
          backgroundColor: Colors.green,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Payment History"),
          backgroundColor: Colors.green,
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment History"),
        backgroundColor: Colors.green,
      ),
      body: _payments.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text("No payments yet."),
              ),
            )
          : ListView.builder(
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final p = _payments[index];
                final method = (p['method'] ?? '').toString().toUpperCase();
                final status = (p['status'] ?? '').toString().toUpperCase();
                final amount = p['amount']?.toString() ?? '';
                final planName = p['plan_name_snapshot'] ?? 'Plan';
                final paidAt = p['paid_at']?.toString().substring(0, 16) ?? '';

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long,
                        color: Colors.green),
                    title: Text("$planName - ₱$amount"),
                    subtitle: Text("Paid via $method on $paidAt"),
                    trailing: Text(
                      status,
                      style: TextStyle(
                        color: status == "PAID" ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
