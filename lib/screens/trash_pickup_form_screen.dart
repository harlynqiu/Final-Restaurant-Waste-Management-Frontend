import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _loadingDrives = true;

  String _pickupOption = "now";
  String? _selectedWasteType;
  int? _selectedDonationDriveId;

  static const Color darwcosGreen = Color(0xFF015704);

  List<dynamic> _donationDrives = [];
  Map<String, dynamic>? _ownerProfile;

  final Map<String, String> _wasteTypes = {
    "customer": "Customer Food Waste",
    "kitchen": "Kitchen Waste",
    "service": "Food Service Waste",
  };

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.pickup?['pickup_address'] ?? "");
    _weightController = TextEditingController(
        text: widget.pickup?['weight_kg']?.toString() ?? "");
    _selectedWasteType = widget.pickup?['waste_type'];

    _fetchOwnerProfile();
    _fetchDonationDrives();
  }

  // ========================================================
  // ✅ Fetch owner profile only (no employee fallback)
  // ========================================================
  Future<void> _fetchOwnerProfile() async {
    try {
      final owner = await ApiService.getOwnerProfile();
      if (owner != null) {
        setState(() {
          _ownerProfile = owner;
          _addressController.text = owner['address'] ?? 'No Address';
        });
        return;
      }

      // No owner found → fail
      _addressController.text = 'No Address';
    } catch (e) {
      _addressController.text = 'No Address';
    }
  }

  // ========================================================
  // ✅ Donation drives
  // ========================================================
  Future<void> _fetchDonationDrives() async {
    try {
      final drives = await ApiService.getDonationDrives();
      setState(() {
        _donationDrives = drives
            .map((d) => {
                  "id": int.tryParse(d["id"].toString()) ?? 0,
                  "title": d["title"] ?? d["name"] ?? "Untitled",
                })
            .toList();
        _loadingDrives = false;
      });
    } catch (e) {
      setState(() {
        _donationDrives = [];
        _loadingDrives = false;
      });
    }
  }

  // ========================================================
  // ✅ Pick Date & Time
  // ========================================================
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
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ========================================================
  // ✅ Submit Pickup
  // ========================================================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDonationDriveId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a donation drive.")),
      );
      return;
    }

    if (_ownerProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Owner profile not found.")),
      );
      return;
    }

    // Scheduled datetime
    DateTime scheduledDate;
    if (_pickupOption == "schedule") {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Select both date and time.")),
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
      scheduledDate = DateTime.now();
    }

    setState(() => _isLoading = true);

    final profile = _ownerProfile!;
    final body = {
      "scheduled_date": scheduledDate.toIso8601String(),
      "weight_kg": double.parse(_weightController.text),
      "pickup_address": _addressController.text,
      "restaurant_name": profile['restaurant_name'],
      "waste_type": _selectedWasteType,
      "donation_drive": _selectedDonationDriveId,
      "latitude": profile['latitude'] ?? 0,
      "longitude": profile['longitude'] ?? 0,
    };

    dynamic result;
    if (widget.pickup == null) {
      final ok = await ApiService.addTrashPickup(body);
      result = ok ? {} : null;
    } else {
      result = await ApiService.updateTrashPickup(widget.pickup!['id'], body);
    }

    setState(() => _isLoading = false);

    if (result != null) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save pickup.")),
      );
    }
  }

  // ========================================================
  // ✅ UI
  // ========================================================
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
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: darwcosGreen),
        title: const Text(
          "Request Pickup",
          style: TextStyle(
            color: darwcosGreen,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
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
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}$')),
                        ],
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Enter weight";
                          final weight = double.tryParse(v);
                          if (weight == null) return "Invalid number";
                          if (weight <= 0) return "Must be > 0 kg";
                          if (weight > 50) return "Cannot exceed 50 kg";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _selectedWasteType,
                        items: _wasteTypes.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedWasteType = v),
                        decoration: _fieldDecoration(
                            label: "Type of Waste",
                            icon: Icons.delete_outline),
                        validator: (v) =>
                            v == null ? "Select waste type" : null,
                      ),

                      const SizedBox(height: 16),

                      _loadingDrives
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: darwcosGreen))
                          : DropdownButtonFormField<int>(
                              isExpanded: true,
                              value: _selectedDonationDriveId,
                              items: _donationDrives
                                  .map((drive) => DropdownMenuItem<int>(
                                        value: drive['id'],
                                        child: Text(
                                          drive['title'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedDonationDriveId = v),
                              decoration: _fieldDecoration(
                                label: "Donation Drive",
                                icon: Icons.volunteer_activism,
                              ),
                              validator: (v) =>
                                  v == null ? "Select a donation drive" : null,
                            ),

                      const SizedBox(height: 24),

                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: darwcosGreen))
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darwcosGreen,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _submit,
                                child: const Text(
                                  "Confirm Pickup",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
