import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';


class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api"; // change to your server IP if on mobile
  //static const String baseUrl = "http://192.168.254.191/api";
  //static const String baseUrl = "http://10.0.2.2:8000/api";


  // ---------------- LOGIN USER ----------------
static Future<bool> loginUser(String username, String password) async {
  final response = await http.post(
    Uri.parse('$baseUrl/token/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', data['access']);
    await prefs.setString('refresh_token', data['refresh']);
    debugPrint("✅ Login successful — tokens saved");
    return true;
  } else {
    debugPrint("❌ Login failed: ${response.body}");
    return false;
  }
}
  // ---------------- REFRESH TOKEN ----------------
static Future<bool> refreshToken() async {
  final prefs = await SharedPreferences.getInstance();
  final refresh = prefs.getString('refresh_token');
  if (refresh == null) return false;

  final response = await http.post(
    Uri.parse('$baseUrl/token/refresh/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'refresh': refresh}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    await prefs.setString('access_token', data['access']);
    debugPrint("🔄 Token refreshed successfully");
    return true;
  } else {
    debugPrint("❌ Token refresh failed: ${response.body}");
    return false;
  }
}


  // --------------------------------------------------------
  // 🧾 REGISTER - Used in SignupScreen
  // --------------------------------------------------------
  static Future<bool> register(
    String username,
    String password, {
    String? email,
    required String restaurantName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/employees/register/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "email": email,
          "restaurant_name": restaurantName,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      // Django returns 201 when created successfully
      if (response.statusCode == 201) {
        print("✅ Registration successful!");
        return true;
      } else {
        print("❌ Registration failed (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Registration error: $e");
      return false;
    }
  }




  // ---------------------------------------------------------
  // GET TRASH PICKUPS
  // ---------------------------------------------------------
  static Future<List<dynamic>> getTrashPickups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    if (token == null) throw Exception("Not authenticated.");

    final url = Uri.parse("$baseUrl/trash_pickups/");
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Unauthorized. Please log in again.");
    } else {
      throw Exception("Failed to load pickups.");
    }
  }

  // ---------------------------------------------------------
  // CREATE NEW PICKUP
  // ---------------------------------------------------------
  static Future<bool> createTrashPickup(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final url = Uri.parse("$baseUrl/trash_pickups/");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  // -----------------------------------
  // GET REWARD POINTS
  // -----------------------------------
  static Future<Map<String, dynamic>> getRewardPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');
    final response = await http.get(
      Uri.parse("$baseUrl/rewards/points/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load reward points");
    }
  }

  // -----------------------------------
  // GET REWARD TRANSACTIONS
  // -----------------------------------
  static Future<List<dynamic>> getRewardTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');
    final response = await http.get(
      Uri.parse("$baseUrl/rewards/transactions/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load transactions");
    }
  }

  // -----------------------------------
  // GET AVAILABLE VOUCHERS
  // -----------------------------------
  static Future<List<dynamic>> getVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');
    final response = await http.get(
      Uri.parse("$baseUrl/rewards/vouchers/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load vouchers");
    }
  }

  // -----------------------------------
  // REDEEM A VOUCHER
  // -----------------------------------
  static Future<String> redeemVoucher(int voucherId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');
    final response = await http.post(
      Uri.parse("$baseUrl/rewards/redeem/"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'voucher_id': voucherId}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['success'] ?? "Redeemed successfully!";
    } else {
      throw Exception(data['error'] ?? "Redemption failed");
    }
  }

    // -----------------------------------
  // GET REDEMPTION HISTORY
  // -----------------------------------
  static Future<List<dynamic>> getRewardRedemptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');
    final response = await http.get(
      Uri.parse("$baseUrl/rewards/redemptions/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load redemption history");
    }
  }

    // ============================
  // SUBSCRIPTION: GET AVAILABLE PLANS
  // ============================
  static Future<List<dynamic>> getPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.get(
      Uri.parse("$baseUrl/subscriptions/plans/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load plans");
    }
  }

  // ============================
  // SUBSCRIPTION: GET MY SUBSCRIPTION
  // ============================
  static Future<Map<String, dynamic>?> getMySubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.get(
      Uri.parse("$baseUrl/subscriptions/mine/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    } else if (res.statusCode == 404) {
      // no subscription yet
      return null;
    } else {
      throw Exception("Failed to load subscription");
    }
  }

  // ============================
  // SUBSCRIPTION: SUBSCRIBE / RENEW
  // ============================
  static Future<Map<String, dynamic>> subscribeToPlan({
    required int planId,
    required String method,
    String? voucherCode, // 👈 added
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final Map<String, dynamic> body = {
      "plan_id": planId,
      "method": method,
    };

    // 👇 include voucher only if provided
    if (voucherCode != null && voucherCode.isNotEmpty) {
      body["voucher_code"] = voucherCode;
    }

    final res = await http.post(
      Uri.parse("$baseUrl/subscriptions/subscribe/"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Subscription failed: ${res.body}");
    }
  }

  // ============================
  // SUBSCRIPTION: CANCEL AUTO-RENEW
  // ============================
  static Future<String> cancelAutoRenew() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.post(
      Uri.parse("$baseUrl/subscriptions/cancel/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['message'] ?? "Cancelled";
    } else {
      throw Exception("Unable to cancel auto-renew");
    }
  }

  // ============================
  // SUBSCRIPTION: PAYMENT HISTORY
  // ============================
  static Future<List<dynamic>> getPaymentHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.get(
      Uri.parse("$baseUrl/subscriptions/payments/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load payments");
    }
  }

    // ============================
  // DONATION DRIVES
  // ============================

  // 🔹 Get all active donation drives
  static Future<List<dynamic>> getDonationDrives() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.get(
      Uri.parse("$baseUrl/donations/drives/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load donation drives");
    }
  }

  // 🔹 Get current user’s donations
  static Future<List<dynamic>> getMyDonations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.get(
      Uri.parse("$baseUrl/donations/participations/"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load donation history");
    }
  }

  // 🔹 Create new donation
  static Future<void> createDonation({
    required int driveId,
    required String item,
    required String quantity,
    String? remarks,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.post(
      Uri.parse("$baseUrl/donations/participations/"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "drive": driveId,
        "donated_item": item,
        "quantity": quantity,
        "remarks": remarks ?? "",
      }),
    );

    if (res.statusCode != 201) {
      throw Exception("Failed to submit donation: ${res.body}");
    }
  }

    // ============================
  // 👥 EMPLOYEES
  // ============================
  static Future<List<dynamic>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access');

    final res = await http.get(
      Uri.parse("$baseUrl/employees/"), // ✅ your Django endpoint
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load employees: ${res.body}");
    }
  }

    // -----------------------------
  // 🧩 AUTH HEADERS
  // -----------------------------
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access");
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  
  // -----------------------------
  // 🔐 LOGOUT
  // -----------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access");
    await prefs.remove("refresh");
  }

  // ---------------- GET CURRENT USER ----------------
static Future<Map<String, dynamic>?> getCurrentUser() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      debugPrint("⚠️ No access token found — user not logged in.");
      return null;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/employees/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint("👤 Current user: $data");
      return data;
    } else if (response.statusCode == 401) {
      debugPrint("🔒 Unauthorized — token may be invalid or expired.");
    } else {
      debugPrint("❌ Failed to fetch user (${response.statusCode}): ${response.body}");
    }
  } catch (e) {
    debugPrint("⚠️ Error fetching user: $e");
  }
  return null;
}

  // -----------------------------
  // 🏆 USER POINTS
  // -----------------------------
  static Future<int> getUserPoints() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return 0;

    final response = await http.get(
      Uri.parse('$baseUrl/rewards/points/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['points'] ?? 0;
    } else {
      debugPrint("❌ getUserPoints failed: ${response.statusCode} - ${response.body}");
      return 0;
    }
  } catch (e) {
    debugPrint("⚠️ getUserPoints error: $e");
    return 0;
  }
}

// get trash pickups auto

static Future<List<dynamic>> getTrashPickupsAuto() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('$baseUrl/trash_pickups/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      debugPrint("❌ getTrashPickups failed: ${response.statusCode} - ${response.body}");
      return [];
    }
  } catch (e) {
    debugPrint("⚠️ getTrashPickups error: $e");
    return [];
  }
}

  // ---------------- UPDATE TRASH PICKUP ----------------
  static Future<bool> updateTrashPickup(int id, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.patch(
        Uri.parse('$baseUrl/trash_pickups/$id/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Pickup $id updated successfully");
        return true;
      } else {
        debugPrint("❌ Failed to update pickup (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Error updating pickup: $e");
      return false;
    }
  }

 // ADD TRASH PICK UP  

static Future<bool> addTrashPickup(Map<String, dynamic> body) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');

    Future<http.Response> makeRequest() {
      return http.post(
        Uri.parse('$baseUrl/trash_pickups/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    }

    var response = await makeRequest();

    if (response.statusCode == 401 &&
        response.body.contains("token_not_valid")) {
      // Try refresh
      final refreshed = await refreshToken();
      if (refreshed) {
        token = prefs.getString('access_token');
        response = await makeRequest();
      }
    }

    if (response.statusCode == 201) {
      debugPrint("✅ Pickup created successfully");
      return true;
    } else {
      debugPrint("❌ Failed (${response.statusCode}): ${response.body}");
      return false;
    }
  } catch (e) {
    debugPrint("⚠️ Error creating pickup: $e");
    return false;
  }
}

}
