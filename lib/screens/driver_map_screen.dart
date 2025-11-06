// lib/screens/driver_map_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';

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
  LatLng? _pickupLocation;
  List<LatLng> _routePoints = [];

  bool _loading = true;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  // ------------------------------------------------
  // ✅ INITIALIZE MAP
  // ------------------------------------------------
  Future<void> _initializeMap() async {
    try {
      await _getDriverLocation();
      _getPickupLocation();

      if (_driverLocation != null && _pickupLocation != null) {
        await _generateRoute();

        // ✅ Center the map properly
        final bounds = LatLngBounds.fromPoints([
          _driverLocation!,
          _pickupLocation!,
        ]);

        if (mounted) {
          _mapController.fitBounds(
            bounds,
            options: const FitBoundsOptions(padding: EdgeInsets.all(40)),
          );
        }
      }

      setState(() => _loading = false);

      // ✅ Update driver location every 10 seconds
      _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _updateDriverLocation();
      });
    } catch (e) {
      debugPrint("❌ Error initializing map: $e");
      setState(() => _loading = false);
    }
  }

  // ------------------------------------------------
  // ✅ DRIVER LOCATION
  // ------------------------------------------------
  Future<void> _getDriverLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    _driverLocation = LatLng(pos.latitude, pos.longitude);
  }

  // 🔁 Update driver location
  Future<void> _updateDriverLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      _driverLocation = LatLng(pos.latitude, pos.longitude);

      await ApiService.updateDriverLocation(pos.latitude, pos.longitude);

      if (_pickupLocation != null) {
        await _generateRoute();
        setState(() {});
      }
    } catch (e) {
      debugPrint("❌ Error updating driver: $e");
    }
  }

  // ------------------------------------------------
  // ✅ PICKUP LOCATION — BACKEND ONLY
  // ------------------------------------------------
  void _getPickupLocation() {
    final lat = widget.pickup['latitude'];
    final lng = widget.pickup['longitude'];

    if (lat == null || lng == null) {
      throw Exception("Pickup coordinates missing in backend response!");
    }

    _pickupLocation = LatLng(
      double.parse(lat.toString()),
      double.parse(lng.toString()),
    );

    debugPrint("✅ Loaded pickup coordinates: $_pickupLocation");
  }

  // ------------------------------------------------
  // ✅ ROUTE GENERATION (OSRM)
  // ------------------------------------------------
  Future<void> _generateRoute() async {
    if (_driverLocation == null || _pickupLocation == null) return;

    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "${_driverLocation!.longitude},${_driverLocation!.latitude};"
        "${_pickupLocation!.longitude},${_pickupLocation!.latitude}"
        "?overview=full&geometries=geojson";

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) {
      debugPrint("🚫 OSRM failed: ${resp.statusCode}");
      return;
    }

    final data = json.decode(resp.body);
    final coords = (data['routes'][0]['geometry']['coordinates'] as List)
        .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
        .toList();

    _routePoints = coords;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------
  // ✅ UI
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: darwcosGreen)),
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
          initialCenter: _pickupLocation!,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            tileProvider: CancellableNetworkTileProvider(),
          ),

          // ✅ ROUTE POLYLINE
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: Colors.blue,
                  strokeWidth: 5,
                ),
              ],
            ),

          // ✅ PICKUP MARKER
          MarkerLayer(
            markers: [
              Marker(
                point: _pickupLocation!,
                width: 50,
                height: 50,
                child: const Icon(Icons.location_on,
                    color: Colors.red, size: 40),
              ),
            ],
          ),

          // ✅ DRIVER MARKER
          if (_driverLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _driverLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.motorcycle,
                      color: Colors.green, size: 40),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
