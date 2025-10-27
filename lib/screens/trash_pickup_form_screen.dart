import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrashPickupFormScreen extends StatefulWidget {
  const TrashPickupFormScreen({super.key});

  @override
  State<TrashPickupFormScreen> createState() => _TrashPickupFormScreenState();
}

class _TrashPickupFormScreenState extends State<TrashPickupFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _restaurantName = TextEditingController();
  final TextEditingController _wasteType = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _pickupAddress = TextEditingController();

  bool _saving = false;

  // -----------------------------------------------------
  // SUCCESS POPUP DIALOG
  // -----------------------------------------------------
  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // must tap "OK" to close
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                "Pickup Request Submitted!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your request has been successfully sent. Our team will process it shortly.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(true); // return to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text("OK, Got it"),
              ),
            ],
          ),
        );
      },
    );
  }

  // -----------------------------------------------------
  // SUBMIT FUNCTION
  // -----------------------------------------------------
  Future<void> _submitPickup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final newPickup = {
      "restaurant_name": _restaurantName.text,
      "waste_type": _wasteType.text,
      "weight_kg": double.tryParse(_weight.text) ?? 0,
      "pickup_address": _pickupAddress.text,
    };

    try {
      bool success = await ApiService.createTrashPickup(newPickup);
      if (!mounted) return;

      if (success) {
        await _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create pickup.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Pickup Request"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _restaurantName,
                decoration: const InputDecoration(
                  labelText: "Restaurant Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _wasteType,
                decoration: const InputDecoration(
                  labelText: "Waste Type (e.g. Food, Plastic)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _weight,
                decoration: const InputDecoration(
                  labelText: "Weight (kg)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _pickupAddress,
                decoration: const InputDecoration(
                  labelText: "Pickup Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _saving ? null : _submitPickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
