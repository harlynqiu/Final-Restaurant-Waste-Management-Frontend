import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'employee_form_screen.dart'; // ✅ new import

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  bool _loading = true;
  List<dynamic> _employees = [];
  String _error = "";
  final TextEditingController _searchController = TextEditingController();

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
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load employees";
        _loading = false;
      });
    }
  }

  Future<void> _navigateToAddEmployee() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
    );
    if (result == true) {
      // Refresh employee list when coming back
      _loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Employees"),
          backgroundColor: darwcosGreen,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Employees"),
          backgroundColor: darwcosGreen,
        ),
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Employees"),
        backgroundColor: darwcosGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "New Employee",
            onPressed: _navigateToAddEmployee,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployees,
        child: Column(
          children: [
            // 🔍 Search bar
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search employee...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _employees = _employees
                        .where((emp) => emp["name"]
                            .toString()
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                  });
                },
              ),
            ),

            // 📋 Employee List
            Expanded(
              child: _employees.isEmpty
                  ? const Center(child: Text("No employees found."))
                  : ListView.builder(
                      itemCount: _employees.length,
                      itemBuilder: (context, index) {
                        final emp = _employees[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: darwcosGreen,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              emp["name"] ?? "Unnamed Employee",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${emp["position"] ?? "No position"}\n${emp["email"] ?? "No email"}",
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.grey, size: 18),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Selected ${emp["name"] ?? "Employee"}"),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
