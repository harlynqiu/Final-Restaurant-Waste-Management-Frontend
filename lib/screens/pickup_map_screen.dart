import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';

class PickupMapScreen extends StatefulWidget {
  final int pickupId;
  final String address;

  const PickupMapScreen({
    super.key,
    required this.pickupId,
    required this.address,
  });

  @override
  State<PickupMapScreen> createState() => _PickupMapScreenState();
}

class _PickupMapScreenState extends State<PickupMapScreen> {
  static const Color darwcosGreen = Color(0xFF015704);

  LatLng? _driverLocation;
  LatLng? _restaurantLocation;
  bool _loading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      // ✅ 1. Get driver's live location
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final driverLatLng = LatLng(pos.latitude, pos.longitude);

      // ✅ 2. Try to convert restaurant address to coordinates (with timeout)
      LatLng? restaurantLatLng;
      try {
        final locs = await locationFromAddress(widget.address)
            .timeout(const Duration(seconds: 8));
        if (locs.isNotEmpty) {
          restaurantLatLng =
              LatLng(locs.first.latitude, locs.first.longitude);
        }
      } catch (e) {
        debugPrint("⚠️ Geocoding failed: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "⚠️ Couldn't locate restaurant address. Showing driver only."),
          ),
        );
      }

      setState(() {
        _driverLocation = driverLatLng;
        _restaurantLocation = restaurantLatLng;
        _loading = false;
      });

      // ✅ 3. Update driver location to backend
      await ApiService.updateDriverLocation(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("🚨 Location load failed: $e");
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("❌ Error loading map: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: darwcosGreen)),
      );
    }

    if (_driverLocation == null) {
      return Scaffold(
        appBar:
            AppBar(title: const Text("Pickup Map"), backgroundColor: darwcosGreen),
        body: const Center(
          child: Text("⚠️ Could not get driver location."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Route"),
        backgroundColor: darwcosGreen,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _restaurantLocation ?? _driverLocation!,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _driverLocation!,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.person_pin_circle,
                  color: Colors.blueAccent,
                  size: 40,
                ),
              ),
              if (_restaurantLocation != null)
                Marker(
                  point: _restaurantLocation!,
                  width: 60,
                  height: 60,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pickup Address:",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: darwcosGreen)),
            Text(widget.address, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: darwcosGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("🚚 Navigation started — on your way!")),
                );
              },
              icon: const Icon(Icons.directions_car),
              label: const Text("Start Navigation"),
            ),
          ],
        ),
      ),
    );
  }
}
