import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SubscriptionPaymentsScreen extends StatefulWidget {
  const SubscriptionPaymentsScreen({super.key});

  @override
  State<SubscriptionPaymentsScreen> createState() =>
      _SubscriptionPaymentsScreenState();
}

class _SubscriptionPaymentsScreenState
    extends State<SubscriptionPaymentsScreen> {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "No date";
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "PAID":
        return Colors.green;
      case "FAILED":
        return Colors.redAccent;
      case "PENDING":
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _methodIcon(String method) {
    switch (method.toUpperCase()) {
      case "GCASH":
        return Icons.phone_android;
      case "CARD":
        return Icons.credit_card;
      case "BANK":
        return Icons.account_balance;
      case "CASH":
        return Icons.payments;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Payment History",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: darwcosGreen),
            )
          : _error.isNotEmpty
              ? Center(
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : _payments.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          "No payments yet.",
                          style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final p = _payments[index];
                          final method =
                              (p['method'] ?? '').toString().toUpperCase();
                          final status =
                              (p['status'] ?? '').toString().toUpperCase();
                          final amount = p['amount']?.toString() ?? '0.00';
                          final planName =
                              p['plan_name_snapshot'] ?? 'Subscription Plan';
                          final paidAt =
                              _formatDate(p['paid_at']?.toString() ?? '');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              leading: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: darwcosGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _methodIcon(method),
                                  color: darwcosGreen,
                                  size: 26,
                                ),
                              ),
                              title: Text(
                                planName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "₱$amount • Paid via $method",
                                      style: const TextStyle(
                                          color: Colors.black54, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      paidAt,
                                      style: const TextStyle(
                                          color: Colors.black45, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _statusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
