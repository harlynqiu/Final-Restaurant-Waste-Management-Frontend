import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api"; // change to your server IP if on mobile
  //static const String baseUrl = "http://192.168.254.191/api";
  //static const String baseUrl = "http://10.0.2.2:8000/api";
  // ---------------------------------------------------------
  // LOGIN: Gets access + refresh token from Django backend
  // ---------------------------------------------------------
  static Future<bool> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/token/");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access', data['access']);
      await prefs.setString('refresh', data['refresh']);
      return true;
    } else {
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

  // -----------------------------
  // 👤 CURRENT USER INFO
  // -----------------------------
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse("$baseUrl/employees/me/"), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to load user info (${response.statusCode})");
    }
  }

  // -----------------------------
  // 🏆 USER POINTS
  // -----------------------------
  static Future<int> getUserPoints() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse("$baseUrl/rewards/points/"), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["points"] ?? 0;
    } else {
      return 0;
    }
  }

}
