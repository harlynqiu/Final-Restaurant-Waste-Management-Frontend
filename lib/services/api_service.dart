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
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
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
      await _setAccessToken(data['access']);
      await _setRefreshToken(data['refresh']);
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
  // 🧾 Register (SignupScreen)
  // ============================
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

      if (response.statusCode == 201) {
        debugPrint("✅ Registration successful!");
        return true;
      } else {
        debugPrint("❌ Registration failed (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Registration error: $e");
      return false;
    }
  }

  // ============================
  // 👤 Current User
  // ============================
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final res = await _withAuthRetry(() async {
        return http.get(
          Uri.parse('$baseUrl/employees/me/'),
          headers: await _authHeaders(),
        );
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint("👤 Current user: $data");
        return data;
      }

      debugPrint("❌ getCurrentUser failed: ${res.statusCode} - ${res.body}");
    } catch (e) {
      debugPrint("⚠️ Error fetching user: $e");
    }
    return null;
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

  static Future<bool> updateTrashPickup(int id, Map<String, dynamic> body) async {
    final res = await _withAuthRetry(() async {
      return http.patch(
        Uri.parse('$baseUrl/trash_pickups/$id/'),
        headers: await _authHeaders(),
        body: jsonEncode(body),
      );
    });

    if (res.statusCode == 200) {
      debugPrint("✅ Pickup $id updated successfully");
      return true;
    } else {
      debugPrint("❌ Failed to update pickup (${res.statusCode}): ${res.body}");
      return false;
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

  static Future<String> redeemVoucher(int voucherId) async {
    final res = await _withAuthRetry(() async {
      return http.post(
        Uri.parse("$baseUrl/rewards/redeem/"),
        headers: await _authHeaders(),
        body: jsonEncode({'voucher_id': voucherId}),
      );
    });

    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return data['success'] ?? "Redeemed successfully!";
    } else {
      throw Exception(data['error'] ?? "Redemption failed");
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
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/employees/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load employees: ${res.statusCode} ${res.body}");
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
      "method": method,
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
      return jsonDecode(res.body);
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
}
