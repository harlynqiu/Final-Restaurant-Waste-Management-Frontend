// lib/screens/driver_map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/api_service.dart';

class DriverMapScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;

  const DriverMapScreen({super.key, required this.pickup});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  static const Color darwcosGreen = Color(0xFF015704);

  final MapController _mapController = MapController();
  LatLng? _driverLocation;
  LatLng? _restaurantLocation;
  bool _loading = true;
  List<LatLng> _routePoints = [];
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  // ---------------- LOAD LOCATIONS ----------------
  Future<void> _loadLocations() async {
    try {
      await _getDriverLocation();
      await _getRestaurantLocation();

      if (_driverLocation != null && _restaurantLocation != null) {
        _generateRoute();
      }

      setState(() => _loading = false);

      // update driver location every 10 seconds
      _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _updateDriverLocation();
      });
    } catch (e) {
      debugPrint("⚠️ Error loading map: $e");
      setState(() => _loading = false);
    }
  }

  // ---------------- DRIVER LOCATION ----------------
    Future<void> _getDriverLocation() async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) await Geolocator.openLocationSettings();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied.");
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      _driverLocation = LatLng(pos.latitude, pos.longitude);
      debugPrint("✅ Driver Location: $_driverLocation");
    }

    Future<void> _updateDriverLocation() async {
      try {
        final pos = await Geolocator.getCurrentPosition();
        setState(() => _driverLocation = LatLng(pos.latitude, pos.longitude));
        await ApiService.updateDriverLocation(pos.latitude, pos.longitude);
      } catch (e) {
        debugPrint("❌ Failed to update driver location: $e");
      }
    }


  // ---------------- RESTAURANT LOCATION ----------------
  Future<void> _getRestaurantLocation() async {
    try {
      final latValue = widget.pickup['latitude'];
      final lngValue = widget.pickup['longitude'];

      double? lat = latValue != null ? double.tryParse(latValue.toString()) : null;
      double? lng = lngValue != null ? double.tryParse(lngValue.toString()) : null;

      if (lat != null && lng != null) {
        _restaurantLocation = LatLng(lat, lng);
        debugPrint("✅ Restaurant coordinates (backend): $_restaurantLocation");
        return;
      }

      final rawAddress = widget.pickup['pickup_address'];
      final address = (rawAddress == null || rawAddress.toString().trim().isEmpty)
          ? ''
          : rawAddress.toString().trim();

      if (address.isEmpty || address.toLowerCase() == 'null') {
        debugPrint("⚠️ Skipping geocoding — invalid address in pickup #${widget.pickup['id']}");
        return;
      }

      debugPrint("📍 Geocoding for: '$address'");
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        _restaurantLocation =
            LatLng(locations.first.latitude, locations.first.longitude);
        debugPrint("✅ Geocoded restaurant: $_restaurantLocation");
      } else {
        debugPrint("⚠️ No geocode results for: '$address'");
      }
    } catch (e) {
      debugPrint("❌ Geocoding failed: $e");
    }
  }

  // ---------------- ROUTE GENERATION ----------------
  void _generateRoute() {
    if (_driverLocation == null || _restaurantLocation == null) return;
    _routePoints = [_driverLocation!, _restaurantLocation!];
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: darwcosGreen),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darwcosGreen,
        title: Text(widget.pickup['restaurant_name'] ?? "Pickup Route"),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _restaurantLocation ?? LatLng(7.0731, 125.6128),
          initialZoom: 13.0,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.darwcos',
          ),
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 5.0,
                  color: Colors.blueAccent,
                ),
              ],
            ),
          if (_restaurantLocation != null)
            MarkerLayer(markers: [
              Marker(
                point: _restaurantLocation!,
                width: 60,
                height: 60,
                child: const Icon(Icons.restaurant, color: Colors.red, size: 40),
              ),
            ]),
          if (_driverLocation != null)
            MarkerLayer(markers: [
              Marker(
                point: _driverLocation!,
                width: 60,
                height: 60,
                child: const Icon(Icons.motorcycle, color: Colors.green, size: 40),
              ),
            ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: darwcosGreen,
        onPressed: () {
          if (_restaurantLocation != null && _driverLocation != null) {
            var bounds = LatLngBounds.fromPoints(
                [_restaurantLocation!, _driverLocation!]);
            _mapController.fitBounds(bounds,
                options: const FitBoundsOptions(padding: EdgeInsets.all(100)));
          }
        },
        icon: const Icon(Icons.zoom_out_map),
        label: const Text("Fit Both"),
      ),
    );
  }
}
