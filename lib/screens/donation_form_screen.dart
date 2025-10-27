import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DonationFormScreen extends StatefulWidget {
  final Map<String, dynamic> drive;

  const DonationFormScreen({super.key, required this.drive});

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _submitting = false;

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      await ApiService.createDonation(
        driveId: widget.drive['id'],
        item: _itemController.text,
        quantity: _quantityController.text,
        remarks: _remarksController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Donation submitted successfully!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Donate to ${widget.drive['title']}"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: "Donated Item",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Please enter item name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity (e.g. 5.0 kg)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Please enter quantity" : null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Remarks (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50)),
                onPressed: _submitting ? null : _submitDonation,
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Donation"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
