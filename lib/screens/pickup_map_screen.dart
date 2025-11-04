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
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _positionStream?.drain();
    super.dispose();
  }

  // ---------------------------------------------------
  // Load driver & restaurant, then compute real route
  // ---------------------------------------------------
  Future<void> _loadLocations() async {
    try {
      // 1. Get driver’s GPS
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final driverLatLng = LatLng(pos.latitude, pos.longitude);

      // 2. Get restaurant coordinates
      LatLng? restaurantLatLng;
      if (widget.latitude != null && widget.longitude != null) {
        restaurantLatLng = LatLng(widget.latitude!, widget.longitude!);
      } else {
        restaurantLatLng = await _getCoordinatesFromAddress(widget.address);
      }

      if (restaurantLatLng == null) {
        throw Exception("Failed to get restaurant coordinates");
      }

      // 3. Fetch OSRM route (real road path)
      final route = await _getDrivingRoute(driverLatLng, restaurantLatLng);

      // 4. Update UI
      if (!mounted) return;
      setState(() {
        _driverLocation = driverLatLng;
        _restaurantLocation = restaurantLatLng;
        _routePoints = route;
        _loading = false;
      });

      // 5. Send driver location to backend & start live tracking
      await ApiService.updateDriverLocation(pos.latitude, pos.longitude);
      _startLiveDriverTracking(restaurantLatLng);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading map: $e")),
        );
      }
    }
  }

  // ---------------------------------------------------
  // Live driver tracking (updates every 10 seconds)
  // ---------------------------------------------------
  void _startLiveDriverTracking(LatLng restaurantLatLng) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );

    _positionStream!.listen((Position pos) async {
      final newDriver = LatLng(pos.latitude, pos.longitude);

      setState(() => _driverLocation = newDriver);

      await ApiService.updateDriverLocation(pos.latitude, pos.longitude);

      // recompute route every few updates for accuracy
      final route = await _getDrivingRoute(newDriver, restaurantLatLng);
      if (mounted) setState(() => _routePoints = route);
    });
  }

  // ---------------------------------------------------
  // Geocoding fallback (OpenStreetMap Nominatim)
  // ---------------------------------------------------
  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      if (address.trim().isEmpty) return null;
      final query = "$address, Davao City, Philippines";
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}",
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'darwcos-app/1.0 (support@darwcos.com)',
      });

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final lat = double.tryParse(results.first['lat'] ?? '');
          final lon = double.tryParse(results.first['lon'] ?? '');
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {}
    return LatLng(7.0731, 125.6128); // fallback to Davao center
  }

  // ---------------------Real driving route via OSRM----------------------------

  Future<List<LatLng>> _getDrivingRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};${end.longitude},${end.latitude}"
        "?overview=full&geometries=geojson",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        return coords
            .map((p) => LatLng(p[1] as double, p[0] as double))
            .toList();
      }
    } catch (e) {
      debugPrint("Route fetch error: $e");
    }
    // fallback straight line
    return [start, end];
  }

  // --------------- UI------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: darwcosGreen)),
      );
    }

    if (_driverLocation == null || _restaurantLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pickup Map"), backgroundColor: darwcosGreen),
        body: const Center(
          child: Text("Unable to fetch locations."),
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
          initialCenter: _driverLocation!,
          initialZoom: 14,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          // Base map
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.darwcos',
          ),

          // Driving route line
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

          // Markers
          MarkerLayer(
            markers: [
              Marker(
                point: _driverLocation!,
                width: 60,
                height: 60,
                child: const Icon(Icons.motorcycle, color: Colors.green, size: 40),
              ),
              Marker(
                point: _restaurantLocation!,
                width: 60,
                height: 60,
                child: const Icon(Icons.restaurant, color: Colors.redAccent, size: 40),
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
            const Text(
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
                final bounds = LatLngBounds.fromPoints(
                  [_restaurantLocation!, _driverLocation!],
                );
                _mapController.fitBounds(
                  bounds,
                  options: const FitBoundsOptions(padding: EdgeInsets.all(80)),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Navigation in progress... following route."),
                  ),
                );
              },
              icon: const Icon(Icons.navigation),
              label: const Text("Follow Route"),
            ),
          ],
        ),
      ),
    );
  }
}
