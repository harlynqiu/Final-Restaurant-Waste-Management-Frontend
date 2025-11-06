import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  // Color palette
  static const Color darwcosGreen = Color(0xFF015704);
  static const Color deepRed = Color(0xFFB71C1C);
  static const Color softGreen = Color(0xFF2E7D32);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF6F8F6);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const double cardRadius = 14;

  bool _loading = true;
  List<dynamic> _employees = [];
  List<dynamic> _filteredEmployees = [];
  String _error = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final data = await ApiService.getEmployees();
      if (!mounted) return;
      setState(() {
        _employees = data;
        _filteredEmployees = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Failed to load employees: $e";
        _loading = false;
      });
    }
  }

  void _filterEmployees(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((emp) {
        final name = emp['name']?.toLowerCase() ?? '';
        final position = emp['position']?.toLowerCase() ?? '';
        final email = emp['email']?.toLowerCase() ?? '';
        return name.contains(lowerQuery) ||
            position.contains(lowerQuery) ||
            email.contains(lowerQuery);
      }).toList();
    });
  }

  Future<void> _deleteEmployee(int id) async {
    try {
      await ApiService.deleteEmployee(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee deleted successfully."),
          backgroundColor: darwcosGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadEmployees();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Delete failed. Please try again."),
          backgroundColor: deepRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Employee",
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this employee?",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: deepRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteEmployee(emp['id']);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
    );
    if (result == true) {
      await Future.delayed(const Duration(milliseconds: 400));
      _loadEmployees();
    }
  } // ← this brace was missing in your file

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darwcosGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Employee Directory",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: darwcosGreen),
            onPressed: _navigateToAddEmployee,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darwcosGreen))
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: deepRed)))
              : RefreshIndicator(
                  color: darwcosGreen,
                  onRefresh: _loadEmployees,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(),
                          _buildSearchBar(),
                          const SizedBox(height: 10),
                          if (_filteredEmployees.isEmpty)
                            _buildNoEmployeesView()
                          else
                            Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 16,
                              runSpacing: 16,
                              children: _filteredEmployees
                                  .map((e) => _buildEmployeeCard(e, screenWidth * 0.38))
                                  .toList(),
                            ),
                          const SizedBox(height: 36),
                          const Center(
                            child: Text(
                              "D.A.R.W.C.O.S",
                              style: TextStyle(
                                color: darwcosGreen,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darwcosGreen,
        onPressed: _navigateToAddEmployee,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Employee",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Header card
  Widget _buildHeaderCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Card(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/employee.png",
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Meet Your Team",
                      style: TextStyle(
                        color: darwcosGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Manage and oversee your restaurant’s employees efficiently.",
                      style: TextStyle(
                        fontSize: 13.5,
                        color: textSecondary,
                        height: 1.35,
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

  // Search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: TextField(
        controller: _searchController,
        onChanged: _filterEmployees,
        style: const TextStyle(color: textPrimary),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: darwcosGreen),
          hintText: "Search by name, position, or email...",
          hintStyle: const TextStyle(color: textSecondary),
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: BorderSide(color: darwcosGreen.withOpacity(0.14)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: BorderSide(color: darwcosGreen.withOpacity(0.14)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(color: darwcosGreen, width: 1.2),
          ),
        ),
      ),
    );
  }

  // No employees view
  Widget _buildNoEmployeesView() {
    return Column(
      children: const [
        Icon(Icons.info_outline, color: textSecondary, size: 56),
        SizedBox(height: 14),
        Text(
          "No employees found.",
          style: TextStyle(
            fontSize: 16,
            color: textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Employee card
  Widget _buildEmployeeCard(Map<String, dynamic> emp, double width) {
    final String name = emp['name'] ?? "Unnamed";
    final String position = emp['position'] ?? "No position";
    final String email = emp['email'] ?? "No email";

    final String initials = name.isNotEmpty
        ? name.trim().split(" ").map((e) => e[0]).take(2).join().toUpperCase()
        : "??";

    final Color avatarColor =
        Colors.primaries[name.hashCode % Colors.primaries.length].withOpacity(0.2);

    return GestureDetector(
      onTap: () => _showEmployeeDetailsBottomSheet(emp),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: darwcosGreen.withOpacity(0.10)),
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: avatarColor,
              child: Text(
                initials,
                style: const TextStyle(
                  color: darwcosGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    position,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  // Employee details bottom sheet
void _showEmployeeDetailsBottomSheet(Map<String, dynamic> emp) {
  final String name = emp['name'] ?? "Unnamed";
  final String position = emp['position'] ?? "No position";
  final String email = emp['email'] ?? "No email";
  final String restaurant = emp['restaurant_name'] ?? "Not assigned";
  final String address = emp['address'] ?? "No address provided";
  final String status = emp['status'] ?? "Active";
  final String date = emp['created_at'] ?? "N/A";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Colors.primaries[name.hashCode % Colors.primaries.length]
                          .withOpacity(0.2),
                  child: Text(
                    name.isNotEmpty
                        ? name.trim().split(" ").map((e) => e[0]).take(2).join().toUpperCase()
                        : "??",
                    style: const TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: darwcosGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.badge_outlined, "Position", position),
            _detailRow(Icons.email_outlined, "Email", email),
            _detailRow(Icons.store_mall_directory_outlined, "Restaurant", restaurant),
            _detailRow(Icons.location_on_outlined, "Address", address),
            _detailRow(Icons.calendar_today_outlined, "Date Added", date),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: darwcosGreen, size: 20),
                const SizedBox(width: 6),
                Text(
                  "Status: ${status.toUpperCase()}",
                  style: const TextStyle(
                    color: darwcosGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // ✅ EDIT + CLOSE BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      "Edit",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: softGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // close sheet

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeFormScreen(employeeData: emp),
                        ),
                      );

                      // Refresh list after update
                      if (result == true) {
                        await Future.delayed(const Duration(milliseconds: 350));
                        _loadEmployees();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    label: const Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darwcosGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

  // Detail row helper
  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
