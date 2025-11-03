import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'reward_redemption_history_screen.dart';
import 'reward_voucher_screen.dart';

class RewardsDashboardScreen extends StatefulWidget {
  const RewardsDashboardScreen({super.key});

  @override
  State<RewardsDashboardScreen> createState() => _RewardsDashboardScreenState();
}

class _RewardsDashboardScreenState extends State<RewardsDashboardScreen>
    with TickerProviderStateMixin {
  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  int _points = 0;
  List<dynamic> _transactions = [];
  List<Map<String, dynamic>> _myRewards = [];

  bool _loading = true;
  bool _loadingMyRewards = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation =
        Tween<double>(begin: 0.0, end: 15.0).animate(_glowController);
    _loadRewards();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    try {
      final pointsData = await ApiService.getRewardPoints();
      final transactionsData = await ApiService.getRewardTransactions();
      final rewardsData = await ApiService.getMyRewards();

      setState(() {
        _points = pointsData['points'] ?? 0;
        _transactions = transactionsData;
        _myRewards = List<Map<String, dynamic>>.from(rewardsData ?? []);
        _loading = false;
      });

      _updateBadgeProgress(_points);
      _fadeController.forward();
      _startGlowEffect();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _startGlowEffect() async {
    setState(() => _isGlowing = true);
    await _glowController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 4));
    await _glowController.reverse();
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

  Color _getTransactionColor(String type) =>
      type == "redeem" ? Colors.redAccent : darwcosGreen;
  IconData _getTransactionIcon(String type) =>
      type == "redeem" ? Icons.remove_circle_outline : Icons.add_circle_outline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : RefreshIndicator(
              onRefresh: _loadRewards,
              child: FadeTransition(
                opacity: _fadeIn,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 🏆 HEADER
                    SliverAppBar(
                      expandedHeight: 260,
                      pinned: true,
                      backgroundColor: darwcosGreen,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: const Text(
                          "Rewards Dashboard",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 🌈 Gradient Background
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF015704),
                                    Color(0xFF037A09),
                                    Color(0xFF04A012),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),

                            // 🎨 Decorative Wave Shape at Bottom
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(40),
                                  ),
                                ),
                              ),
                            ),

                            // 🏅 Icon + Points
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 800),
                                      height: _isGlowing ? 120 : 110,
                                      width: _isGlowing ? 120 : 110,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            blurRadius:
                                                _isGlowing ? 30 : 20,
                                            spreadRadius:
                                                _isGlowing ? 10 : 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.15),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: const Icon(
                                        Icons.emoji_events_rounded,
                                        color: Colors.white,
                                        size: 65,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "$_points Points",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Earn rewards for every completed pickup",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🎯 POINTS + BADGE SECTION
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text("My Points",
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: darwcosGreen)),
                                        const SizedBox(height: 10),
                                        Text("$_points pts",
                                            style: const TextStyle(
                                                fontSize: 38,
                                                fontWeight: FontWeight.bold,
                                                color: darwcosGreen)),
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
                                              color: Colors.black54),
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
                                    return Card(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              "assets/images/trash_badge1.png",
                                              height: 60,
                                              width: 60,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(_currentBadge,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 14)),
                                            const SizedBox(height: 6),
                                            Text("Next: $_nextBadge",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 🧾 HISTORY + REDEEM VOUCHERS BUTTONS
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RewardRedemptionHistoryScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.history,
                                    color: darwcosGreen),
                                label: const Text(
                                  "View History",
                                  style: TextStyle(
                                      color: darwcosGreen,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side:
                                      const BorderSide(color: darwcosGreen),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RewardVoucherScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.card_giftcard,
                                    color: Colors.white),
                                label: const Text(
                                  "Redeem Vouchers",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darwcosGreen,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🧾 TRANSACTION HISTORY
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: const Text(
                          "Transaction History",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    _transactions.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Center(
                                child: Text(
                                  "No transactions yet.",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.black54),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final t = _transactions[i];
                                final type =
                                    t['transaction_type'] ?? 'earn';
                                final color = _getTransactionColor(type);
                                final icon = _getTransactionIcon(type);
                                final prefix =
                                    type == "redeem" ? "-" : "+";

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.grey.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          color.withOpacity(0.1),
                                      child: Icon(icon, color: color),
                                    ),
                                    title: Text(
                                      t['description'] ?? "Transaction",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                    subtitle: Text(
                                        "Date: ${t['created_at'].toString().substring(0, 16)}"),
                                    trailing: Text(
                                      "$prefix${t['points']} pts",
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                              childCount: _transactions.length,
                            ),
                          ),

                    // 🎁 MY REWARDS SECTION
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: const Text(
                          "My Rewards",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    _myRewards.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  "You haven’t redeemed any rewards yet.",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final reward = _myRewards[i];
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.card_giftcard,
                                            color: darwcosGreen, size: 40),
                                        const SizedBox(height: 8),
                                        Text(
                                          reward["reward_name"] ?? "Reward",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Type: ${reward["reward_type"] ?? "N/A"}",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${reward["points"] ?? 0} pts",
                                          style: const TextStyle(
                                              color: darwcosGreen,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _myRewards.length,
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
