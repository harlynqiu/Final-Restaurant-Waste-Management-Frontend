import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RewardsDashboardScreen extends StatefulWidget {
  const RewardsDashboardScreen({super.key});

  @override
  State<RewardsDashboardScreen> createState() => _RewardsDashboardScreenState();
}

class _RewardsDashboardScreenState extends State<RewardsDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color darwcosGreen = Color(0xFF015704);

  int _points = 0;
  bool _loading = true;
  bool _loadingMyRewards = false;
  bool _loadingVouchers = false;

  List<Map<String, dynamic>> _myRewards = [];
  List<dynamic> _vouchers = [];

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isGlowing = false;

  String _currentBadge = "First Trash Hero";
  String _nextBadge = "Bronze Collector";
  double _progress = 0.0;
  int _pointsToNext = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation =
        Tween<double>(begin: 0.0, end: 15.0).animate(_glowController);
    _fetchAllData();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([
      _fetchPoints(),
      _fetchVouchers(),
      _fetchMyRewards(),
    ]);
  }

  Future<void> _fetchPoints() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getRewardPoints();
      final points = data['points'] ?? 0;
      if (!mounted) return;
      if (points > _points && !_isGlowing) _startGlowEffect();
      _updateBadgeProgress(points);
      setState(() {
        _points = points;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchVouchers() async {
    setState(() => _loadingVouchers = true);
    try {
      final data = await ApiService.getVouchers();
      setState(() => _vouchers = data ?? []);
    } catch (_) {}
    setState(() => _loadingVouchers = false);
  }

  Future<void> _fetchMyRewards() async {
    setState(() => _loadingMyRewards = true);
    try {
      final data = await ApiService.getMyRewards();
      setState(() => _myRewards = List<Map<String, dynamic>>.from(data ?? []));
    } catch (_) {}
    setState(() => _loadingMyRewards = false);
  }

  void _startGlowEffect() async {
    setState(() => _isGlowing = true);
    await _glowController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 4));
    _glowController.stop();
    setState(() => _isGlowing = false);
  }

  void _updateBadgeProgress(int pts) {
    int previous = 0;
    int next = 100;
    String current = "First Trash Hero";
    String upcoming = "Bronze Collector";

    if (pts >= 100 && pts < 250) {
      previous = 100;
      next = 250;
      current = "Bronze Collector";
      upcoming = "Silver Recycler";
    } else if (pts >= 250 && pts < 500) {
      previous = 250;
      next = 500;
      current = "Silver Recycler";
      upcoming = "Gold Waste Warrior";
    } else if (pts >= 500) {
      previous = 500;
      next = 1000;
      current = "Gold Waste Warrior";
      upcoming = "Eco Legend 🌎";
    }

    final progress =
        ((pts - previous) / (next - previous)).clamp(0.0, 1.0).toDouble();
    final remaining = (next - pts).clamp(0, next);

    setState(() {
      _currentBadge = current;
      _nextBadge = upcoming;
      _progress = progress;
      _pointsToNext = remaining;
    });
  }

  Future<void> _redeemVoucher(int id, String name, int cost) async {
    if (_points < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("❌ Not enough points."),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Redemption"),
        content: Text("Redeem '$name' for $cost points?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: darwcosGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await ApiService.redeemVoucher(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Voucher redeemed successfully!"),
          backgroundColor: darwcosGreen,
        ));
        await _fetchAllData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("❌ Redemption failed."),
          backgroundColor: Colors.redAccent,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: true,
        title: const Text(
          "Rewards",
          style: TextStyle(
            color: darwcosGreen,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: darwcosGreen),
      ),
      body: Stack(
        children: [
          Container(height: 180, width: double.infinity, color: darwcosGreen),
          RefreshIndicator(
            onRefresh: _fetchAllData,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildPointsAndBadgeSection(),
                const SizedBox(height: 30),
                const Text(
                  "Available Vouchers",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darwcosGreen,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loadingVouchers)
                  const Center(child: CircularProgressIndicator())
                else if (_vouchers.isEmpty)
                  const Text("No vouchers available right now.")
                else
                  ..._vouchers.map((v) => _buildVoucherCard(v)).toList(),
                const SizedBox(height: 30),
                const Text(
                  "My Rewards",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darwcosGreen,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loadingMyRewards)
                  const Center(child: CircularProgressIndicator())
                else if (_myRewards.isEmpty)
                  const Center(
                      child: Text("You haven’t redeemed any rewards yet."))
                else
                  ..._myRewards.map((r) => _buildMyRewardCard(r)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(dynamic voucher) {
    final name = voucher['name'] ?? 'Voucher';
    final description = voucher['description'] ?? '';
    final points = voucher['points_required'] ?? 0;
    final imageUrl = voucher['image'];
    final id = voucher['id'];

    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.card_giftcard,
                      color: darwcosGreen, size: 50),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(description,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text("$points pts",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: darwcosGreen)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: darwcosGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _redeemVoucher(id, name, points),
              child: const Text("Redeem",
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyRewardCard(Map<String, dynamic> reward) {
    final voucher = reward['voucher'] ?? {};
    final name = voucher['name'] ?? reward['item_name'] ?? 'Reward';
    final status = reward['status'] ?? 'completed';
    final points = reward['points_spent'] ?? voucher['points_required'] ?? 0;
    final imageUrl = voucher['image'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 40, height: 40),
              )
            : const Icon(Icons.card_giftcard, color: darwcosGreen),
        title: Text(name),
        subtitle: Text("Status: $status"),
        trailing: Text(
          "$points pts",
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: darwcosGreen),
        ),
      ),
    );
  }

  Widget _buildPointsAndBadgeSection() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "My Points",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: darwcosGreen,
                          ),
                        ),
                        IconButton(
                          onPressed: _fetchPoints,
                          icon: const Icon(Icons.refresh, color: darwcosGreen),
                        ),
                      ],
                    ),
                    Text(
                      _loading ? "..." : "$_points pts",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[200],
                      color: darwcosGreen,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _points >= 1000
                          ? "🏆 Max badge achieved!"
                          : "$_pointsToNext pts to $_nextBadge",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    boxShadow: _isGlowing
                        ? [
                            BoxShadow(
                              color: darwcosGreen.withOpacity(0.4),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: _glowAnimation.value / 3,
                            ),
                          ]
                        : [],
                  ),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/trash_badge1.png",
                            height: 60,
                            width: 60,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _currentBadge,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Next: $_nextBadge",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
