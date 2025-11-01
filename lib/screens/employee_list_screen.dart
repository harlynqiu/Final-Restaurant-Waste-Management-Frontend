import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool _loading = true;
  List<dynamic> _employees = [];
  String _error = "";

  static const Color darwcosGreen = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await ApiService.getEmployees();
      setState(() {
        _employees = data;
        _loading = false;
        _error = "";
      });
    } catch (e) {
      setState(() {
        _error = "❌ Failed to load employees: $e";
        _loading = false;
      });
    }
  }

  Future<void> _navigateToAddEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
    );
    if (result == true) _loadEmployees();
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
          "Employee Directory",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _loadEmployees,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Add New Employee",
            onPressed: _navigateToAddEmployee,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : _error.isNotEmpty
              ? _buildErrorState()
              : _employees.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadEmployees,
                      color: darwcosGreen,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        children: [
                          
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _employees
                                .map((emp) => _buildEmployeeTile(emp))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddEmployee,
        backgroundColor: darwcosGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Employee",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 🧍 Interactive employee tile with hover and tap effects
  Widget _buildEmployeeTile(Map<String, dynamic> emp) {
    return _HoverableCard(
      child: Container(
        width: 420,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: darwcosGreen.withOpacity(0.15),
              child: const Icon(Icons.person, color: darwcosGreen, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp['name'] ?? "Unnamed Employee",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${emp['position'] ?? 'No position'} • ${emp['email'] ?? 'No email'}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌿 Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_outlined,
                size: 90, color: darwcosGreen.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              "No employees yet",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darwcosGreen),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tap the Add button below to create your first employee record.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // 🚨 Error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 80),
            const SizedBox(height: 16),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: darwcosGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loadEmployees,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Retry",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🌿 Hoverable Card widget for subtle interactive animation
class _HoverableCard extends StatefulWidget {
  final Widget child;
  const _HoverableCard({required this.child});

  @override
  State<_HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<_HoverableCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hovering
            ? (Matrix4.identity()..scale(1.02))
            : Matrix4.identity(),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _hovering
                  ? Colors.black12.withOpacity(0.2)
                  : Colors.black12.withOpacity(0.05),
              blurRadius: _hovering ? 10 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Employee tapped!")),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
