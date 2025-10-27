import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardVoucherScreen extends StatefulWidget {
  const RewardVoucherScreen({super.key});

  @override
  State<RewardVoucherScreen> createState() => _RewardVoucherScreenState();
}

class _RewardVoucherScreenState extends State<RewardVoucherScreen> {
  bool _loading = true;
  List<dynamic> _vouchers = [];
  String _message = "";

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final data = await ApiService.getVouchers();
      setState(() {
        _vouchers = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _message = "Error loading vouchers.";
      });
    }
  }

  Future<void> _redeemVoucher(int id) async {
    try {
      final msg = await ApiService.redeemVoucher(id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _loadVouchers();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_vouchers.isEmpty) {
      return const Center(child: Text("No vouchers available."));
    }

    return ListView.builder(
      itemCount: _vouchers.length,
      itemBuilder: (context, index) {
        final item = _vouchers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.green),
            title: Text(item['name']),
            subtitle: Text(item['description']),
            trailing: ElevatedButton(
              onPressed: () => _redeemVoucher(item['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("${item['points_required']} pts"),
            ),
          ),
        );
      },
    );
  }
}
