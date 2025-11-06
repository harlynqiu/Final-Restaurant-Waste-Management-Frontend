import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DriverToPickupMap extends StatefulWidget {
  final Map<String, dynamic> pickup;      // must include latitude, longitude
  final double driverLat;
  final double driverLng;

  const DriverToPickupMap({
    super.key,
    required this.pickup,
    required this.driverLat,
    required this.driverLng,
  });

  @override
  State<DriverToPickupMap> createState() => _DriverToPickupMapState();
}

class _DriverToPickupMapState extends State<DriverToPickupMap> {
  final MapController _mapController = MapController();
  List<LatLng> _route = [];
  bool _loadingRoute = true;
  String _error = '';

  double _asDouble(dynamic v) {
    if (v == null) throw Exception('Missing coordinate');
    if (v is num) return v.toDouble();
    return double.parse(v.toString());
  }

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      // ✅ Use backend coordinates directly (no geocoding)
      final double pickupLat = _asDouble(widget.pickup['latitude']);
      final double pickupLng = _asDouble(widget.pickup['longitude']);

      final double driverLat = widget.driverLat;
      final double driverLng = widget.driverLng;

      // ✅ OSRM expects LON,LAT order in the URL
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${driverLng},${driverLat};${pickupLng},${pickupLat}'
          '?overview=full&geometries=geojson';

      // Debug log to confirm order
      // print(url);

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        throw Exception('OSRM failed: ${resp.statusCode}');
      }

      final data = json.decode(resp.body);
      final coords = (data['routes'][0]['geometry']['coordinates'] as List)
          .map<LatLng>((c) => LatLng(
                // GeoJSON coordinates are [lon, lat]
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      setState(() {
        _route = coords;
        _loadingRoute = false;
        _error = '';
      });

      // Center the map between driver and pickup
      final bounds = LatLngBounds.fromPoints([
        LatLng(driverLat, driverLng),
        LatLng(pickupLat, pickupLng),
      ]);
      bounds.extend(LatLng(driverLat, driverLng));
      bounds.extend(LatLng(pickupLat, pickupLng));
      _mapController.fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(32)));
    } catch (e) {
      setState(() {
        _loadingRoute = false;
        _error = 'Failed to load route: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double pickupLat = _asDouble(widget.pickup['latitude']);
    final double pickupLng = _asDouble(widget.pickup['longitude']);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(pickupLat, pickupLng),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a','b','c'],
        ),
        // ✅ Route polyline
        if (_route.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: _route, strokeWidth: 5.0),
            ],
          ),
        // ✅ Markers: flutter_map wants (lat, lng)
        MarkerLayer(
          markers: [
            // Pickup pin (red)
            Marker(
              point: LatLng(pickupLat, pickupLng),
              width: 40,
              height: 40,
              child: const Icon(Icons.location_on, size: 40, color: Colors.red),
            ),
            // Driver pin (green)
            Marker(
              point: LatLng(widget.driverLat, widget.driverLng),
              width: 36,
              height: 36,
              child: const Icon(Icons.two_wheeler, size: 36, color: Colors.green),
            ),
          ],
        ),
      ],
    );
  }
}
