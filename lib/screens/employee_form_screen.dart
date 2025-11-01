import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _position = TextEditingController();

  bool _saving = false;
  static const Color darwcosGreen = Color(0xFF015704);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await ApiService.addEmployee(
        name: _name.text.trim(),
        email: _email.text.trim(),
        position: _position.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Employee added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to add employee: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration _fieldDecoration({
      required String label,
      IconData? icon,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: darwcosGreen.withOpacity(0.8))
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        labelStyle: TextStyle(color: Colors.grey[700]),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Add Employee",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // ✅ limits width
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🖼️ Add Employee Image
                      Image.asset(
                        "assets/images/add_employee.png",
                        height: 80,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "New Employee Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darwcosGreen,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 👤 Name
                      TextFormField(
                        controller: _name,
                        decoration: _fieldDecoration(
                          label: "Full Name",
                          icon: Icons.person_outline,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter employee name" : null,
                      ),
                      const SizedBox(height: 16),

                      // ✉️ Email
                      TextFormField(
                        controller: _email,
                        decoration: _fieldDecoration(
                          label: "Email Address",
                          icon: Icons.email_outlined,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter email address" : null,
                      ),
                      const SizedBox(height: 16),

                      // 🧾 Position
                      TextFormField(
                        controller: _position,
                        decoration: _fieldDecoration(
                          label: "Position / Role",
                          icon: Icons.work_outline,
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter employee position" : null,
                      ),

                      const SizedBox(height: 28),

                      _saving
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: darwcosGreen),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darwcosGreen,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.person_add_alt_1,
                                    color: Colors.white),
                                label: const Text(
                                  "Save Employee",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _save,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
