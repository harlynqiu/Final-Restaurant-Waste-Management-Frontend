import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _restaurantController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;

  static const Color darwcosGreen = Color(0xFF015704);

  @override
  void initState() {
    super.initState();
    _initLocationOnce();
  }

  Future<void> _initLocationOnce() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable location services.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission permanently denied.")),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _selectedLocation = LatLng(pos.latitude, pos.longitude));
      await _updateAddressFromLatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint("Location init error: $e");
    }
  }

  Future<void> _updateAddressFromLatLng(double lat, double lng) async {
    try {
      final url = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng";
      final response = await http.get(Uri.parse(url), headers: {
        "User-Agent": "DARWCOSApp/1.0"
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _addressController.text = data["display_name"] ?? "Unknown location";
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
  }

  Future<List<dynamic>> _searchAddress(String query) async {
    try {
      final url = "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5";
      final response = await http.get(Uri.parse(url), headers: {
        "User-Agent": "DARWCOSApp/1.0"
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
    return [];
  }

  Future<void> _openMapPicker() async {
    if (_selectedLocation == null) {
      await _initLocationOnce();
    }

    LatLng tempLocation = _selectedLocation ?? LatLng(7.0731, 125.6128);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        TextEditingController searchCtrl = TextEditingController();
        List<dynamic> searchResults = [];

        return StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Column(
              children: [
                // --- sheet handle bar ---
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 12),

                // --- search bar ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      prefixIcon: const Icon(Icons.search, color: darwcosGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (query) async {
                      if (query.trim().length < 3) {
                        setModalState(() => searchResults = []);
                        return;
                      }

                      searchResults = await _searchAddress(query.trim());
                      setModalState(() {});
                    },
                  ),
                ),

                // --- LIVE SEARCH LIST ---
                if (searchResults.isNotEmpty)
                  Expanded(
                    flex: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, i) {
                          final item = searchResults[i];
                          return ListTile(
                            title: Text(item["display_name"]),
                            onTap: () {
                              tempLocation = LatLng(
                                double.parse(item["lat"]),
                                double.parse(item["lon"]),
                              );
                              _mapController.move(tempLocation, 16);
                              setModalState(() => searchResults = []);
                              searchCtrl.text = item["display_name"];
                            },
                          );
                        },
                      ),
                    ),
                  ),

                // --- MAP ---
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: tempLocation,
                          initialZoom: 16,
                          onPositionChanged: (pos, _) {
                            if (pos.center != null) {
                              tempLocation = pos.center!;
                              setModalState(() {});
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          ),
                        ],
                      ),

                      // ✅ Center Pin
                      const Icon(Icons.location_pin,
                          color: darwcosGreen, size: 48),

                      // ✅ Floating Button — use my location
                      Positioned(
                        right: 16,
                        bottom: 20,
                        child: FloatingActionButton(
                          backgroundColor: darwcosGreen,
                          mini: true,
                          child: const Icon(Icons.my_location, color: Colors.white),
                          onPressed: () async {
                            final pos = await Geolocator.getCurrentPosition();
                            tempLocation = LatLng(pos.latitude, pos.longitude);
                            _mapController.move(tempLocation, 17);
                            setModalState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // --- CONFIRM BUTTON ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darwcosGreen,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);

                      setState(() {
                        _selectedLocation = tempLocation;
                        _addressController.text = "Loading address...";
                      });

                      await _updateAddressFromLatLng(
                        tempLocation.latitude,
                        tempLocation.longitude,
                      );
                    },
                    label: const Text(
                      "Confirm Location",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _register() async {
    if (_restaurantController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter restaurant name and confirm address.")),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please set your restaurant location.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.registerOwner(
    username: _usernameController.text.trim(),
    password: _passwordController.text.trim(),
    email: _emailController.text.trim(),
    restaurantName: _restaurantController.text.trim(),
    address: _addressController.text.trim(),
    latitude: _selectedLocation!.latitude,
    longitude: _selectedLocation!.longitude,
  );


    setState(() => _isLoading = false);

    if (response["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Registration successful.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "Registration failed.")),
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset("assets/images/black_philippine_eagle.png", width: 100),
                    const SizedBox(height: 10),
                    const Text(
                      "Register Your Restaurant",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darwcosGreen,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField("Username", _usernameController, Icons.person),
                    const SizedBox(height: 16),
                    _buildField("Email (optional)", _emailController, Icons.email),
                    const SizedBox(height: 16),
                    _buildField("Password", _passwordController, Icons.lock, obscure: true),
                    const SizedBox(height: 16),
                    _buildField("Restaurant Name", _restaurantController, Icons.store),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _addressController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Restaurant Address",
                        prefixIcon: const Icon(Icons.location_on_outlined, color: darwcosGreen),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.push_pin, color: darwcosGreen, size: 26),
                          onPressed: _openMapPicker,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: darwcosGreen)
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darwcosGreen,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _register,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          ),
                          child: const Text(
                            "Sign in",
                            style: TextStyle(fontWeight: FontWeight.bold, color: darwcosGreen),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: darwcosGreen),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: darwcosGreen),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: darwcosGreen, width: 2),
        ),
      ),
    );
  }
}
