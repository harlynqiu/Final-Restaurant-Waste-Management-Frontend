import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TrashPickupFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pickup;

  const TrashPickupFormScreen({super.key, this.pickup});

  @override
  State<TrashPickupFormScreen> createState() => _TrashPickupFormScreenState();
}

class _TrashPickupFormScreenState extends State<TrashPickupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _weightController;
  final TextEditingController _searchController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  int _points = 0;

  String _pickupOption = "now";
  String? _selectedWasteType;

  static const Color darwcosGreen = Color.fromARGB(255, 1, 87, 4);

  final Map<String, String> _wasteTypes = {
    "customer": "Customer Food Waste",
    "kitchen": "Kitchen Waste",
    "service": "Food Service Waste",
  };

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.pickup?['address'] ?? "");
    _weightController = TextEditingController(
        text: widget.pickup?['trash_weight']?.toString() ?? "");
    _selectedWasteType = widget.pickup?['waste_type'];
    _fetchPoints();
    _fetchUserAddress();
  }

  // ---------------- FETCH USER ADDRESS ----------------
  Future<void> _fetchUserAddress() async {
    if (widget.pickup != null) return;
    try {
      final user = await ApiService.getCurrentUser();
      if (user != null) {
        setState(() {
          _addressController.text =
              user['restaurant_name'] ?? 'Restaurant Address';
        });
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch user address: $e");
    }
  }

  // ---------------- FETCH POINTS ----------------
  Future<void> _fetchPoints() async {
    final pts = await ApiService.getUserPoints();
    if (!mounted) return;
    setState(() => _points = pts);
  }

  // ---------------- DATE/TIME PICKERS ----------------
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ---------------- CONFIRMATION DIALOG ----------------
  Future<bool> _confirmPickupNow() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Pickup Now"),
            content: const Text(
                "Would you like to schedule this pickup for right now?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: darwcosGreen),
                child: const Text("Yes, Proceed"),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ---------------- SUBMIT PICKUP ----------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime scheduledDate;

    if (_pickupOption == "schedule") {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select both date and time for your pickup")),
        );
        return;
      }

      scheduledDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    } else {
      // "Pick up now" option → ask for confirmation
      final confirmed = await _confirmPickupNow();
      if (!confirmed) return;
      scheduledDate = DateTime.now();
    }

    setState(() => _isLoading = true);

    final Map<String, dynamic> body = {
      "scheduled_date": scheduledDate.toIso8601String(),
      "weight_kg": double.parse(_weightController.text),
      "pickup_address": _addressController.text,
      "restaurant_name": _addressController.text,
      "waste_type": _selectedWasteType,
    };

    dynamic result;
    if (widget.pickup == null) {
      final success = await ApiService.addTrashPickup(body);
      result = success ? {} : null;
    } else {
      result = await ApiService.updateTrashPickup(widget.pickup!['id'], body);
    }

    setState(() => _isLoading = false);

    if (result != null) {
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.pickup == null
              ? "Pickup scheduled successfully!"
              : "Pickup updated successfully!"),
          backgroundColor: darwcosGreen,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save pickup")),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    InputDecoration _fieldDecoration({
      required String label,
      IconData? icon,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, color: darwcosGreen.withOpacity(0.7)) : null,
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          titleSpacing: 0,
          title: Row(
            children: [
              Text(
                widget.pickup == null ? "Add Pickup" : "Edit Pickup",
                style: const TextStyle(
                  color: darwcosGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: darwcosGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$_points pts",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _addressController,
                        readOnly: true,
                        decoration: _fieldDecoration(
                            label: "Restaurant Address",
                            icon: Icons.location_on),
                        validator: (v) =>
                            v == null || v.isEmpty ? "Address missing" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _weightController,
                        decoration: _fieldDecoration(
                            label: "Weight (kg)", icon: Icons.scale),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Enter weight" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedWasteType,
                        items: _wasteTypes.entries
                            .map((entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedWasteType = v),
                        decoration: _fieldDecoration(
                            label: "Type of Waste",
                            icon: Icons.delete_outline),
                        validator: (v) =>
                            v == null ? "Select waste type" : null,
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        "Pickup Option",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darwcosGreen,
                        ),
                      ),
                      RadioListTile<String>(
                        title: const Text("Pick up now"),
                        value: "now",
                        activeColor: darwcosGreen,
                        groupValue: _pickupOption,
                        onChanged: (v) => setState(() => _pickupOption = v!),
                      ),
                      RadioListTile<String>(
                        title: const Text("Schedule a time"),
                        value: "schedule",
                        activeColor: darwcosGreen,
                        groupValue: _pickupOption,
                        onChanged: (v) => setState(() => _pickupOption = v!),
                      ),

                      if (_pickupOption == "schedule") ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              _selectedDate == null
                                  ? "No date selected"
                                  : "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _pickDate,
                              child: const Text("Pick Date",
                                  style: TextStyle(color: darwcosGreen)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _selectedTime == null
                                  ? "No time selected"
                                  : "Time: ${_selectedTime!.format(context)}",
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _pickTime,
                              child: const Text("Pick Time",
                                  style: TextStyle(color: darwcosGreen)),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(
                              child:
                                  CircularProgressIndicator(color: darwcosGreen),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darwcosGreen,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.save, color: Colors.white),
                                label: Text(
                                  widget.pickup == null
                                      ? "Confirm Pickup"
                                      : "Save Changes",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: _submit,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Image.asset(
              "assets/images/black_philippine_eagle.png",
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
