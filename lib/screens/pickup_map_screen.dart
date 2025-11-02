// lib/screens/pickup_map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class PickupMapScreen extends StatefulWidget {
  final int pickupId;
  final String address;
  final double? latitude;
  final double? longitude;

  const PickupMapScreen({
    super.key,
    required this.pickupId,
    required this.address,
    this.latitude,
    this.longitude,
  });

  @override
  State<PickupMapScreen> createState() => _PickupMapScreenState();
}

class _PickupMapScreenState extends State<PickupMapScreen> {
  static const Color darwcosGreen = Color(0xFF015704);

  LatLng? _driverLocation;
  LatLng? _restaurantLocation;
  List<LatLng> _routePoints = [];
  bool _loading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  // ---------------------------------------------------
  // 🚀 Load both driver and restaurant locations
  // ---------------------------------------------------
  Future<void> _loadLocations() async {
    try {
      // ✅ 1. Get driver’s live GPS
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final driverLatLng = LatLng(pos.latitude, pos.longitude);

      // ✅ 2. Use backend coordinates if available
      LatLng? restaurantLatLng;
      if (widget.latitude != null && widget.longitude != null) {
        restaurantLatLng = LatLng(widget.latitude!, widget.longitude!);
        debugPrint("✅ Using provided coordinates: $restaurantLatLng");
      } else {
        restaurantLatLng = await _getCoordinatesFromAddress(widget.address);
      }

      // ✅ 3. Build route following real roads (OSRM)
      List<LatLng> route = [];
      if (driverLatLng != null && restaurantLatLng != null) {
        route = await _getDrivingRoute(driverLatLng, restaurantLatLng);
      }

      if (!mounted) return;
      setState(() {
        _driverLocation = driverLatLng;
        _restaurantLocation = restaurantLatLng;
        _routePoints = route;
        _loading = false;
      });

      // ✅ 4. Update driver location to backend
      await ApiService.updateDriverLocation(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("🚨 Location load failed: $e");
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error loading map: $e")),
        );
      }
    }
  }

  // ---------------------------------------------------
  // 🌍 Geocoding fallback (OpenStreetMap)
  // ---------------------------------------------------
  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      if (address.trim().isEmpty) {
        debugPrint("⚠️ Empty address — cannot geocode");
        return null;
      }

      final query = "$address, Davao City, Philippines";
      debugPrint("🌍 Geocoding via OpenStreetMap for: $query");

      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}",
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'darwcos-app/1.0 (support@darwcos.com)',
      });

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final first = results.first;
          final lat = double.tryParse(first['lat'] ?? '');
          final lon = double.tryParse(first['lon'] ?? '');
          if (lat != null && lon != null) {
            debugPrint("✅ Nominatim result: ($lat, $lon)");
            return LatLng(lat, lon);
          }
        }
        debugPrint("⚠️ No geocode results for: $query");
      } else {
        debugPrint("🚫 Nominatim failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Geocoding error: $e");
    }

    // Default fallback to Davao City center
    return LatLng(7.0731, 125.6128);
  }

  // ---------------------------------------------------
  // 🛣️ Get driving route from OSRM (free routing API)
  // ---------------------------------------------------
  Future<List<LatLng>> _getDrivingRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final points = coords
            .map((p) => LatLng(p[1] as double, p[0] as double))
            .toList();
        debugPrint("✅ OSRM route received: ${points.length} points");
        return points;
      } else {
        debugPrint("⚠️ OSRM failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Route fetch error: $e");
    }
    // fallback to straight line
    return [start, end];
  }

  // ---------------------------------------------------
  // 🧭 UI
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: darwcosGreen)),
      );
    }

    if (_driverLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pickup Map"), backgroundColor: darwcosGreen),
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
          // 🗺️ Base map
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.darwcos',
          ),

          // 🚗 Route line
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

          // 📍 Markers
          MarkerLayer(
            markers: [
              Marker(
                point: _driverLocation!,
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.motorcycle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              Marker(
                point: _restaurantLocation ?? LatLng(7.0731, 125.6128),
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.restaurant,
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
            Text(
              "Pickup Address:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darwcosGreen,
              ),
            ),
            Text(widget.address, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: darwcosGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: () {
                if (_restaurantLocation != null && _driverLocation != null) {
                  var bounds = LatLngBounds.fromPoints(
                    [_restaurantLocation!, _driverLocation!],
                  );
                  _mapController.fitBounds(
                    bounds,
                    options: const FitBoundsOptions(padding: EdgeInsets.all(100)),
                  );
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("🚚 Navigation started — on your way!"),
                  ),
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
