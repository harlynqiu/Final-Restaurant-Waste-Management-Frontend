// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // ============================
  // 🔗 BASE URL (pick ONE)
  // ============================
  // Desktop/Web (Django on same machine):
  static const String baseUrl = "http://127.0.0.1:8000/api";
   // static const String baseUrl = "http://192.168.254.191/api";
  // Android emulator:
  // static const String baseUrl = "http://10.0.2.2:8000/api";
  // Physical phone on same Wi-Fi (replace with your PC's LAN IP):
  // static const String baseUrl = "http://192.168.254.191:8000/api";

  // ============================
  // 🔐 Token Keys + Helpers
  // ============================
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  static Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccess);
  }

  static Future<void> _setAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, token);
  }

  static Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefresh);
  }

  static Future<void> _setRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRefresh, token);
  }

  static Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }

    static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  /// Runs a request; if it returns 401 once, try refresh token and repeat.
  static Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() makeRequest,
  ) async {
    var res = await makeRequest();
    if (res.statusCode != 401) return res;

    final refreshed = await refreshToken();
    if (!refreshed) return res;

    // Retry once after successful refresh
    res = await makeRequest();
    return res;
  }


  // ============================
  // 👤 Auth
  // ============================
    static Future<bool> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      // ✅ Store under the same key that all other requests use
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      debugPrint("✅ Login successful — tokens saved");
      return true;
    } else {
      debugPrint("❌ Login failed: ${response.body}");
      return false;
    }
  }

  static Future<bool> refreshToken() async {
    final refresh = await _getRefreshToken();
    if (refresh == null) return false;

    final res = await http.post(
      Uri.parse('$baseUrl/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _setAccessToken(data['access']);
      debugPrint("🔄 Token refreshed successfully");
      return true;
    } else {
      debugPrint("❌ Token refresh failed: ${res.body}");
      return false;
    }
  }

  static Future<void> logout() async {
    await _clearTokens();
  }


  // ============================
  // 👤 REGISTER USER / EMPLOYEE (Updated)
  // ============================
static Future<bool> register({
  required String username,
  required String password,
  required String email,
  required String name,
  required String position,
  String? restaurantName,
  String? address,
  double? latitude,
  double? longitude,
}) async {
  final url = Uri.parse("$baseUrl/employees/register/");

  final body = jsonEncode({
    "username": username.trim(),
    "password": password.trim(),
    "email": email.trim(),
    "name": name.trim(),
    "position": position.trim(),
    "restaurant_name": restaurantName?.trim() ?? "",
    "address": address?.trim() ?? "",
    "latitude": latitude,      // ✅ added
    "longitude": longitude,    // ✅ added
  });

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 201) {
      debugPrint("✅ Registration successful → ${response.body}");
      return true;
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      debugPrint("⚠️ Validation error: $data");
      return false;
    } else if (response.statusCode == 405) {
      debugPrint("🚫 Method Not Allowed — check your Django route /api/employees/register/");
      return false;
    } else {
      debugPrint("❌ Registration failed (${response.statusCode}): ${response.body}");
      return false;
    }
  } catch (e) {
    debugPrint("🔥 Registration error: $e");
    return false;
  }
}

  // ---------------- GET CURRENT USER ----------------
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token'); // ✅ must match above
    final url = Uri.parse("$baseUrl/users/me/");

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user details (${response.statusCode})");
    }
  }

  // 🛑 Cancel a pickup
  static Future<bool> cancelPickup(int pickupId) async {
    try {
      final res = await _withAuthRetry(() async {
        return http.patch(
          Uri.parse("$baseUrl/trash_pickups/$pickupId/cancel/"),
          headers: await _authHeaders(),
        );
      });

      debugPrint("🛑 [PATCH] Cancel pickup #$pickupId → ${res.statusCode}");

      if (res.statusCode == 200) {
        debugPrint("✅ Pickup #$pickupId cancelled successfully!");
        return true;
      } else {
        debugPrint("❌ Failed to cancel pickup: ${res.statusCode} → ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Cancel pickup exception: $e");
      return false;
    }
  }


  // ------------------------------
  // Get Auth Headers (with JWT Token)
  // ------------------------------
  static Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================
  // 🗑️ Trash Pickups
  // ============================
  static Future<List<dynamic>> getTrashPickups() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/trash_pickups/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    if (res.statusCode == 401) {
      throw Exception("Unauthorized. Please log in again.");
    }

    throw Exception("Failed to load pickups: ${res.statusCode} ${res.body}");
  }

  // Optional alias that matches your older call sites
  static Future<List<dynamic>> getTrashPickupsAuto() => getTrashPickups();

  static Future<bool> createTrashPickup(Map<String, dynamic> data) async {
    final res = await _withAuthRetry(() async {
      return http.post(
        Uri.parse("$baseUrl/trash_pickups/"),
        headers: await _authHeaders(),
        body: jsonEncode(data),
      );
    });

    if (res.statusCode == 201) return true;
    debugPrint("❌ Create pickup failed (${res.statusCode}): ${res.body}");
    return false;
  }

  static Future<bool> addTrashPickup(Map<String, dynamic> body) async {
    // kept for backward compatibility; same as create
    return createTrashPickup(body);
  }

  static Future<Map<String, dynamic>?> updateTrashPickup(
      int id, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.patch(
        Uri.parse('$baseUrl/trash_pickups/$id/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        final body = jsonDecode(response.body);
        debugPrint("✅ Pickup #$id updated successfully → ${body['status']}");
        return body;
      } else {
        debugPrint("❌ Failed to update pickup #$id: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("🚨 Error updating pickup #$id: $e");
      return null;
    }
  }

  // ============================
  // 🏆 Rewards
  // ============================
  // If you need the raw object (e.g., {"points": 10, ...})
  static Future<Map<String, dynamic>> getRewardPoints() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/rewards/points/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to load reward points: ${res.statusCode}");
  }

  // If you only need the integer points (used by your UI chip)
  static Future<int> getUserPoints() async {
    try {
      final res = await _withAuthRetry(() async {
        return http.get(
          Uri.parse('$baseUrl/rewards/points/'),
          headers: await _authHeaders(),
        );
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['points'] ?? 0;
      } else {
        debugPrint("❌ getUserPoints failed: ${res.statusCode} - ${res.body}");
        return 0;
      }
    } catch (e) {
      debugPrint("⚠️ getUserPoints error: $e");
      return 0;
    }
  }

  static Future<List<dynamic>> getRewardTransactions() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/rewards/transactions/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load transactions: ${res.statusCode}");
    }
  }

  static Future<List<dynamic>> getVouchers() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/rewards/vouchers/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load vouchers: ${res.statusCode}");
    }
  }

// ✅ Redeem a voucher (returns bool + handles messages)
static Future<bool> redeemVoucher(int voucherId) async {
  try {
    final res = await _withAuthRetry(() async {
      return http.post(
        Uri.parse("$baseUrl/rewards/redeem/"),
        headers: await _authHeaders(),
        body: jsonEncode({'voucher_id': voucherId}),
      );
    });

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      debugPrint("✅ Voucher redeemed successfully → $data");
      return true;
    } else {
      debugPrint("❌ Failed to redeem voucher → ${res.statusCode}: ${res.body}");
      return false;
    }
  } catch (e) {
    debugPrint("⚠️ redeemVoucher exception: $e");
    return false;
  }
}

  static Future<List<dynamic>> getRewardRedemptions() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/rewards/redemptions/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load redemption history: ${res.statusCode}");
    }
  }

  // ============================
  // 👥 Employees
  // ============================
   static Future<List<dynamic>> getEmployees() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  final response = await http.get(
    Uri.parse('$baseUrl/employees/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // ✅ required for auth
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    debugPrint('❌ Failed to load employees: ${response.statusCode} ${response.body}');
    throw Exception('Failed to load employees');
  }
}

  static Future<void> addEmployee({
    required String name,
    required String email,
    required String position,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.post(
      Uri.parse('$baseUrl/employees/'), // ✅ Correct endpoint
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'username': email.split('@')[0], // required for backend
        'password': 'default123',
        'name': name,
        'email': email,
        'position': position,
        'restaurant_name': 'My Restaurant',
        'address': 'Davao City',
      }),
    );

    if (response.statusCode != 201) {
      debugPrint('❌ Failed to add employee: ${response.statusCode} ${response.body}');
      throw Exception('Failed to add employee');
    }
  }


  // ============================
  // 💳 Subscriptions
  // ============================
  static Future<List<dynamic>> getPlans() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/subscriptions/plans/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load plans: ${res.statusCode}");
    }
  }

  static Future<Map<String, dynamic>?> getMySubscription() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/subscriptions/mine/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    } else if (res.statusCode == 404) {
      return null; // no subscription yet
    } else {
      throw Exception("Failed to load subscription: ${res.statusCode}");
    }
  }

  static Future<Map<String, dynamic>> subscribeToPlan({
    required int planId,
    required String method,
    String? voucherCode,
  }) async {
    final body = <String, dynamic>{
      "plan_id": planId,
      "payment_method": method,
    };
    if (voucherCode != null && voucherCode.isNotEmpty) {
      body["voucher_code"] = voucherCode;
    }

    final res = await _withAuthRetry(() async {
      return http.post(
        Uri.parse("$baseUrl/subscriptions/subscribe/"),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
    });

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Subscription failed: ${res.body}");
    }
  }

  static Future<String> cancelAutoRenew() async {
    final res = await _withAuthRetry(() async {
      return http.post(
        Uri.parse("$baseUrl/subscriptions/cancel/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['message'] ?? "Cancelled";
    } else {
      throw Exception("Unable to cancel auto-renew: ${res.statusCode}");
    }
  }

  static Future<List<dynamic>> getPaymentHistory() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/subscriptions/payments/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load payments: ${res.statusCode}");
    }
  }

  // ============================
  // 🎁 Donation Drives
  // ============================
  static Future<List<dynamic>> getDonationDrives() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/donations/drives/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      // ✅ Ensure it always returns a list
      if (body is Map && body.containsKey("results")) {
        return body["results"];
      } else if (body is List) {
        return body;
      } else {
        throw Exception("Unexpected donation drive format");
      }
    } else {
      throw Exception("Failed to load donation drives: ${res.statusCode}");
    }
  }

  static Future<List<dynamic>> getMyDonations() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/donations/participations/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load donation history: ${res.statusCode}");
    }
  }

  static Future<void> createDonation({
    required int driveId,
    required String item,
    required String quantity,
    String? remarks,
  }) async {
    final res = await _withAuthRetry(() async {
      return http.post(
        Uri.parse("$baseUrl/donations/participations/"),
        headers: await _authHeaders(),
        body: jsonEncode({
          "drive": driveId,
          "donated_item": item,
          "quantity": quantity,
          "remarks": remarks ?? "",
        }),
      );
    });

    if (res.statusCode != 201) {
      throw Exception("Failed to submit donation: ${res.statusCode} ${res.body}");
    }
  }

  // ---------------- FETCH MY REWARDS ----------------
  static Future<List<dynamic>> getMyRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final url = Uri.parse('$baseUrl/rewards/my_rewards/'); // adjust if needed

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is List ? data : [];
    } else {
      debugPrint("❌ Failed to load my rewards: ${response.body}");
      return [];
    }
  }

  // ============================
  // 🚗 Drivers
  // ============================

  // Fetch the logged-in driver profile
  static Future<Map<String, dynamic>?> getCurrentDriver() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/drivers/me/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      debugPrint("❌ Failed to load driver: ${res.statusCode}");
      return null;
    }
  }

  // Update driver availability status
  static Future<bool> updateDriverStatus(String newStatus) async {
    final res = await _withAuthRetry(() async {
      return http.patch(
        Uri.parse("$baseUrl/drivers/me/status/"),
        headers: await _authHeaders(),
        body: jsonEncode({"status": newStatus}),
      );
    });

    return res.statusCode == 200;
  }


    // 🔐 Helper – builds request headers
    static Future<Map<String, String>> _getHeaders() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token"); // adjust key name if different
      return {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };
    }

    // 👤 Fetch driver profile
    static Future<Map<String, dynamic>> getDriverProfile() async {
      final response = await http.get(
        Uri.parse('$baseUrl/drivers/me/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load driver profile');
      }
    }

// ============================
// 🚗 DRIVER PICKUP INTEGRATION
// ============================

// 🟢 Fetch all available pickups (unassigned)
static Future<List<dynamic>> getAvailablePickups() async {
  final response = await http.get(
    Uri.parse('$baseUrl/trash_pickups/available/'), // ✅ Matches Django route
    headers: await getAuthHeaders(),
  );

  debugPrint("📦 [GET] Available pickups → ${response.statusCode}");
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    debugPrint("❌ Failed to load pickups: ${response.body}");
    throw Exception('Failed to load available pickups');
  }
}

  // 🟢 Accept a pickup (driver claims it)
  static Future<bool> acceptPickup(int pickupId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/trash_pickups/$pickupId/accept/'), // ✅ Matches /api/trash_pickups/<id>/accept/
      headers: await getAuthHeaders(),
    );

    debugPrint("🚚 [PATCH] Accept pickup #$pickupId → ${response.statusCode}");
    if (response.statusCode == 200) {
      debugPrint("✅ Pickup #$pickupId accepted successfully!");
      return true;
    } else {
      debugPrint("❌ Failed to accept pickup: ${response.body}");
      return false;
    }
  }

  // 🟢 Mark pickup as completed (driver)
  static Future<bool> completePickup(int pickupId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/trash_pickups/$pickupId/complete/'),
      headers: await getAuthHeaders(),
    );

    debugPrint("✅ [PATCH] Complete pickup #$pickupId → ${response.statusCode}");
    return response.statusCode == 200;
  }

  // 🟢 Fetch driver’s assigned pickups
  static Future<List<dynamic>> getAssignedPickups() async {
    final response = await http.get(
      Uri.parse('$baseUrl/trash_pickups/'),
      headers: await getAuthHeaders(),
    );

    debugPrint("🚚 [GET] Assigned pickups → ${response.statusCode}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("❌ Failed to load assigned pickups: ${response.body}");
      throw Exception('Failed to load assigned pickups');
    }
  }

  // ✅ Fixed: Uses proper token and refresh retry
  static Future<Map<String, dynamic>?> getMyEmployeeProfile() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse('$baseUrl/employees/me/'),
        headers: await getAuthHeaders(),
      );
    });

    debugPrint("👤 [GET] /employees/me → ${res.statusCode} ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 401) {
      debugPrint("⚠️ Unauthorized — token missing or invalid");
      return null;
    } else {
      debugPrint("⚠️ Failed to fetch employee profile: ${res.statusCode} ${res.body}");
      return null;
    }
  }

  // ============================
  // 🚗 UPDATE DRIVER LOCATION
  // ============================
  static Future<bool> updateDriverLocation(double latitude, double longitude) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAccess);

    if (token == null) {
      if (kDebugMode) print("❌ No token found. User not logged in.");
      return false;
    }

    final url = Uri.parse("$baseUrl/drivers/update_location/");
    if (kDebugMode) print("📡 [PATCH] Update driver location → $url");

    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode == 200) {
      if (kDebugMode) print("✅ Location updated successfully → ${response.body}");
      return true;
    } else if (response.statusCode == 404) {
      if (kDebugMode) print("❌ [404] Driver not found → ${response.body}");
      return false;
    } else if (response.statusCode == 401) {
      if (kDebugMode) print("❌ [401] Unauthorized → ${response.body}");
      return false;
    } else {
      if (kDebugMode) print("⚠️ Unexpected error → ${response.statusCode}: ${response.body}");
      return false;
    }
  } catch (e) {
    if (kDebugMode) print("❌ Exception updating location: $e");
    return false;
  }
}

//start pickup 

static Future<bool> startPickup(int id) async {
  final token = await _getAccessToken();
  final response = await http.patch(
    Uri.parse('$baseUrl/trash_pickups/$id/start/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    debugPrint("🚀 Pickup #$id started successfully!");
    return true;
  } else {
    debugPrint("❌ Failed to start pickup #$id → ${response.body}");
    return false;
  }
}

//complete pickup 
static Future<Map<String, dynamic>> completePickupDetailed(int id) async {
  final token = await _getAccessToken();
  final url = Uri.parse('$baseUrl/trash_pickups/$id/complete/');
  final response = await http.patch(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  try {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"success": false, "message": response.body};
    }
  } catch (e) {
    debugPrint("❌ Error decoding completePickup: $e");
    return {"success": false, "message": "Decoding error"}; 
  }
}


}
