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
  LatLng? _restaurantLocation;
  List<LatLng> _routePoints = [];
  bool _loading = true;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initMapData();
  }

  // ------------------------------------------------
  // 🚀 INITIAL LOAD (Get both locations)
  // ------------------------------------------------
  Future<void> _initMapData() async {
    try {
      await _getDriverLocation();
      await _getRestaurantLocation();

      if (_driverLocation != null && _restaurantLocation != null) {
        _generateRoute();
      }

      setState(() => _loading = false);

      // 🔁 Update driver location every 10 seconds
      _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _updateDriverLocation();
      });
    } catch (e) {
      debugPrint("⚠️ Error initializing map: $e");
      setState(() => _loading = false);
    }
  }

  // ------------------------------------------------
  // 📍 DRIVER LOCATION
  // ------------------------------------------------
  Future<void> _getDriverLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied.");
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    _driverLocation = LatLng(pos.latitude, pos.longitude);
    debugPrint("✅ Initial driver location: $_driverLocation");
  }

  // 🔁 Update every 10s
  Future<void> _updateDriverLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _driverLocation = LatLng(pos.latitude, pos.longitude));

      final success = await ApiService.updateDriverLocation(
        pos.latitude,
        pos.longitude,
      );

      if (success) {
        debugPrint("✅ Driver location sent to server");
      } else {
        debugPrint("⚠️ Failed to send driver location to server");
      }
    } catch (e) {
      debugPrint("❌ Error updating driver location: $e");
    }
  }

  // ------------------------------------------------
  // 🏠 RESTAURANT LOCATION (with OpenStreetMap fallback)
  // ------------------------------------------------
  Future<void> _getRestaurantLocation() async {
    try {
      final latValue = widget.pickup['latitude'];
      final lngValue = widget.pickup['longitude'];

      // ✅ CASE 1: Use backend coordinates if available
      if (latValue != null && lngValue != null) {
        final lat = double.tryParse(latValue.toString());
        final lng = double.tryParse(lngValue.toString());
        if (lat != null && lng != null) {
          _restaurantLocation = LatLng(lat, lng);
          debugPrint("✅ Using backend coordinates: $_restaurantLocation");
          if (mounted) _mapController.move(_restaurantLocation!, 15.0);
          return;
        }
      }

      // ✅ CASE 2: Try OpenStreetMap (Nominatim) geocoding
      final rawAddress = widget.pickup['pickup_address']?.toString().trim() ?? '';
      final restaurantName = widget.pickup['restaurant_name']?.toString().trim() ?? '';

      final query = (rawAddress.isNotEmpty && rawAddress.toLowerCase() != 'null')
          ? "$restaurantName, $rawAddress, Davao City, Philippines"
          : "$restaurantName, Davao City, Philippines";

      if (query.isEmpty) {
        debugPrint("⚠️ No address available for pickup ${widget.pickup['id']}");
        return;
      }

      debugPrint("🌍 Geocoding via OpenStreetMap for: $query");

      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}",
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'darwcos-app/1.0 (support@darwcos.com)', // required by Nominatim
      });

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final first = results.first;
          final lat = double.tryParse(first['lat'] ?? '');
          final lon = double.tryParse(first['lon'] ?? '');
          if (lat != null && lon != null) {
            _restaurantLocation = LatLng(lat, lon);
            debugPrint("✅ Nominatim result: $_restaurantLocation");
            if (mounted) _mapController.move(_restaurantLocation!, 15.0);
            return;
          }
        }
        debugPrint("⚠️ No Nominatim results for $query");
      } else {
        debugPrint("🚫 Nominatim API failed: ${response.statusCode}");
      }

      // ✅ CASE 3: Fallback — use Davao City center
      _restaurantLocation = LatLng(7.0731, 125.6128);
      debugPrint("📍 Default fallback (Davao City).");
    } catch (e) {
      debugPrint("❌ OpenStreetMap geocoding error: $e");
      _restaurantLocation = LatLng(7.0731, 125.6128);
    }
  }

  // ------------------------------------------------
  // 🗺️ ROUTE GENERATION
  // ------------------------------------------------
  void _generateRoute() {
    if (_driverLocation == null || _restaurantLocation == null) return;
    _routePoints = [_driverLocation!, _restaurantLocation!];
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------
  // 🧭 UI
  // ------------------------------------------------
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
            tileProvider: CancellableNetworkTileProvider(),
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
              [_restaurantLocation!, _driverLocation!],
            );
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
