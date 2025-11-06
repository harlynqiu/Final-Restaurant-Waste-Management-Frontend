// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ======================================================
  // 🔗 BASE URL (auto: Web→127.0.0.1, Android Emulator→10.0.2.2)
  //   - You can change the web/lan values below if needed.
  // ======================================================
  static const String _webBase = "http://127.0.0.1:8000/api";
  static const String _androidEmulatorBase = "http://10.0.2.2:8000/api";
  static String get baseUrl => kIsWeb ? _webBase : _androidEmulatorBase;

  // ======================================================
  // 🔐 TOKEN STORAGE
  // ======================================================
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

  // ======================================================
  // 🧰 HEADERS & AUTH RETRY
  // ======================================================
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Kept for compatibility (some screens call this directly)
  static Future<Map<String, String>> getAuthHeaders() => _authHeaders();

  /// Wrap a request; if it returns 401, refresh token once and retry.
  static Future<http.Response> _withAuthRetry(
    Future<http.Response> Function() makeRequest,
  ) async {
    var res = await makeRequest();
    if (res.statusCode != 401) return res;

    final refreshed = await refreshToken();
    if (!refreshed) return res;

    res = await makeRequest();
    return res;
  }

  // ======================================================
  // 🔄 REFRESH TOKEN
  // ======================================================
  static Future<bool> refreshToken() async {
    try {
      final refresh = await _getRefreshToken();
      if (refresh == null) {
        debugPrint("⚠️ No refresh token");
        return false;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await _setAccessToken(data['access']);
        debugPrint("🔄 Token refreshed");
        return true;
      } else {
        debugPrint("❌ Refresh failed: ${res.body}");
        await _clearTokens();
        return false;
      }
    } catch (e) {
      debugPrint("🔥 Refresh exception: $e");
      return false;
    }
  }

  // ======================================================
  // 👤 AUTH
  // ======================================================
  static Future<Map<String, dynamic>> loginUser(
    String username,
    String password,
  ) async {
    try {
      // -------------------------------
      // 1) LOGIN: Get access + refresh token
      // -------------------------------
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode != 200) {
        return {"success": false, "message": "Invalid username or password"};
      }

      final tokenData = jsonDecode(response.body);
      final access = tokenData["access"];
      final refresh = tokenData["refresh"];

      await _setAccessToken(access);
      await _setRefreshToken(refresh);

      final authHeader = {
        'Authorization': 'Bearer $access',
        'Content-Type': 'application/json',
      };

      final prefs = await SharedPreferences.getInstance();

      // -------------------------------
      // 2) CHECK IF USER IS DRIVER
      // -------------------------------
      final driverRes = await http.get(
        Uri.parse('$baseUrl/drivers/me/'),
        headers: authHeader,
      );

      if (driverRes.statusCode == 200) {
        final profile = jsonDecode(driverRes.body);
        final status = (profile["status"] ?? "").toString().toLowerCase();

        // ✅ SAVE ROLE
        await prefs.setString("role", "driver");
        await prefs.setBool("logged_in", true);

        return {
          "success": true,
          "role": "driver",
          "verified": status == "active" || status == "available",
          "profile": profile,
        };
      }

      // -------------------------------
      // 3) CHECK IF USER IS OWNER
      // -------------------------------
      final ownerRes = await http.get(
        Uri.parse('$baseUrl/accounts/me/'),
        headers: authHeader,
      );

      if (ownerRes.statusCode == 200) {
        // ✅ SAVE ROLE
        await prefs.setString("role", "owner");
        await prefs.setBool("logged_in", true);

        return {
          "success": true,
          "role": "owner",
          "verified": true,
          "profile": jsonDecode(ownerRes.body),
        };
      }

      // -------------------------------
      // 4) FALLBACK → OWNER
      // (You said: treat any unknown as owner)
      // -------------------------------
      await prefs.setString("role", "owner");
      await prefs.setBool("logged_in", true);

      return {
        "success": true,
        "role": "owner",
        "verified": true,
        "profile": {},
      };

    } catch (e) {
      return {"success": false, "message": "Unexpected error: $e"};
    }
  }

  static Future<void> logout() async => _clearTokens();

  // ======================================================
  // 🧑‍🍳 OWNER REGISTRATION & PROFILE
  // ======================================================
  static Future<Map<String, dynamic>> registerOwner({
    required String username,
    required String password,
    String? email,
    required String restaurantName,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/accounts/register/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username.trim(),
          "password": password.trim(),
          "email": (email ?? "").trim(),
          "restaurant_name": restaurantName.trim(),
          "address": address.trim(),
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      if (res.statusCode == 201) {
        return {
          "success": true,
          "message": "Registration successful.",
          "data": jsonDecode(res.body),
        };
      }

      return {
        "success": false,
        "message": "Registration failed.",
        "details": res.body,
      };
    } catch (e) {
      return {"success": false, "message": "Unexpected error: $e"};
    }
  }

  static Future<bool> isRestaurantNameAvailable(String name) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/accounts/check_restaurant/?name=${Uri.encodeComponent(name)}'),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data["available"] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getOwnerProfile() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse('$baseUrl/accounts/me/'),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return null;
  }

  // ======================================================
  // 🚗 DRIVERS
  // ======================================================
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
      debugPrint("❌ getCurrentDriver: ${res.statusCode} ${res.body}");
      return null;
    }
  }

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

  static Future<bool> updateDriverLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final res = await _withAuthRetry(() async {
        return http.patch(
          Uri.parse("$baseUrl/drivers/update_location/"),
          headers: await _authHeaders(),
          body: jsonEncode({"latitude": latitude, "longitude": longitude}),
        );
      });

      if (res.statusCode == 200) {
        debugPrint("✅ Driver location updated");
        return true;
      } else {
        debugPrint("❌ update_location → ${res.statusCode}: ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("🔥 update_location exception: $e");
      return false;
    }
  }

  // ======================================================
  // 🧺 TRASH PICKUPS (Owner + Driver)
  // ======================================================
  static Future<List<dynamic>> getTrashPickups() async {
    try {
      final res = await _withAuthRetry(() async {
        return http.get(
          Uri.parse("$baseUrl/trash_pickups/"),
          headers: await _authHeaders(),
        );
      });

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      throw Exception("Failed: ${res.statusCode} → ${res.body}");
    } catch (e) {
      debugPrint("Exception getTrashPickups: $e");
      rethrow;
    }
  }

  static Future<bool> createTrashPickup(Map<String, dynamic> data) async {
    try {
      final res = await _withAuthRetry(() async {
        return http.post(
          Uri.parse("$baseUrl/trash_pickups/"),
          headers: await _authHeaders(),
          body: jsonEncode(data),
        );
      });

      if (res.statusCode == 201) {
        debugPrint("✅ Trash pickup created");
        return true;
      } else {
        debugPrint("❌ Create pickup → ${res.statusCode}: ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("🔥 createTrashPickup: $e");
      return false;
    }
  }

  // Alias for older screens
  static Future<bool> addTrashPickup(Map<String, dynamic> data) =>
      createTrashPickup(data);

  static Future<Map<String, dynamic>?> updateTrashPickup(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _withAuthRetry(() async {
        return http.patch(
          Uri.parse("$baseUrl/trash_pickups/$id/"),
          headers: await _authHeaders(),
          body: jsonEncode(data),
        );
      });

      if (res.statusCode == 200) return jsonDecode(res.body);
      debugPrint("❌ Update #$id → ${res.statusCode}: ${res.body}");
      return null;
    } catch (e) {
      debugPrint("🔥 updateTrashPickup: $e");
      return null;
    }
  }

  static Future<bool> cancelPickup(int pickupId) async {
    final res = await _withAuthRetry(() async {
      return http.patch(
        Uri.parse("$baseUrl/trash_pickups/$pickupId/cancel/"),
        headers: await _authHeaders(),
      );
    });
    return res.statusCode == 200;
  }

  // -------- Driver-focused helpers --------
  static Future<List<dynamic>> getAvailablePickups() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse('$baseUrl/trash_pickups/available/'),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      debugPrint("❌ available → ${res.statusCode} ${res.body}");
      throw Exception('Failed to load available pickups');
    }
  }

  static Future<bool> acceptPickup(int pickupId) async {
    final res = await _withAuthRetry(() async {
      return http.patch(
        Uri.parse('$baseUrl/trash_pickups/$pickupId/accept/'),
        headers: await _authHeaders(),
      );
    });
    return res.statusCode == 200;
  }

  static Future<bool> startPickup(int id) async {
    final res = await _withAuthRetry(() async {
      return http.patch(
        Uri.parse('$baseUrl/trash_pickups/$id/start/'),
        headers: await _authHeaders(),
      );
    });
    return res.statusCode == 200;
  }

  static Future<bool> completePickup(int pickupId) async {
    final res = await _withAuthRetry(() async {
      return http.patch(
        Uri.parse('$baseUrl/trash_pickups/$pickupId/complete/'),
        headers: await _authHeaders(),
      );
    });
    return res.statusCode == 200;
  }

  static Future<List<dynamic>> getAssignedPickups() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse('$baseUrl/trash_pickups/'),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      debugPrint("❌ assigned → ${res.statusCode} ${res.body}");
      throw Exception('Failed to load assigned pickups');
    }
  }

  // ======================================================
  // 🏅 REWARDS
  // ======================================================
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
      }
      return 0;
    } catch (e) {
      debugPrint("getUserPoints error: $e");
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getRewardPoints() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/rewards/points/"),
        headers: await _authHeaders(),
      );
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load reward points: ${res.statusCode}");
  }

  static Future<List<dynamic>> getRewardTransactions() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/rewards/transactions/"),
        headers: await _authHeaders(),
      );
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load transactions: ${res.statusCode}");
  }

  static Future<List<dynamic>> getVouchers() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/rewards/vouchers/"),
        headers: await _authHeaders(),
      );
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load vouchers: ${res.statusCode}");
  }

  static Future<bool> redeemVoucher(int voucherId) async {
    try {
      final res = await _withAuthRetry(() async {
        return http.post(
          Uri.parse("$baseUrl/rewards/redeem/"),
          headers: await _authHeaders(),
          body: jsonEncode({'voucher_id': voucherId}),
        );
      });
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("redeemVoucher exception: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getMyRewards() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse('$baseUrl/rewards/my_rewards/'),
        headers: await _authHeaders(),
      );
    });
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data is List ? data : [];
    }
    return [];
  }

  // ---------------------- REWARD REDEMPTIONS ----------------------
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

  // ======================================================
  // 🎁 DONATIONS
  // ======================================================
  static Future<List<dynamic>> getDonationDrives() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/donations/drives/"),
        headers: await _authHeaders(),
      );
    });

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is Map && body.containsKey("results")) return body["results"];
      if (body is List) return body;
      throw Exception("Unexpected donation drive format");
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
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load donation history: ${res.statusCode}");
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

  // ======================================================
  // 👥 EMPLOYEES (records only — no /employees/me/)
  // ======================================================
  static Future<List<dynamic>> getEmployees() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse('$baseUrl/employees/'),
        headers: await _authHeaders(),
      );
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    debugPrint('❌ getEmployees: ${res.statusCode} ${res.body}');
    throw Exception('Failed to load employees');
  }

  /// Create an employee record under the current owner’s restaurant.
  static Future<void> addEmployee({
    required String name,
    required String email,
    required String position,
  }) async {
    final owner = await getOwnerProfile();
    if (owner == null) {
      throw Exception('Failed to identify current restaurant');
    }
    final restaurantName = owner['restaurant_name'] ?? 'Unknown Restaurant';
    final address = owner['address'] ?? 'Unknown Address';

    final res = await _withAuthRetry(() async {
      return http.post(
        Uri.parse('$baseUrl/employees/'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'username': email.split('@')[0],
          'password': 'default123',
          'name': name,
          'email': email,
          'position': position,
          'restaurant_name': restaurantName,
          'address': address,
        }),
      );
    });

    if (res.statusCode != 201) {
      throw Exception('Failed to add employee → ${res.body}');
    }
  }

  static Future<void> updateEmployee(
    int id, {
    required String name,
    required String email,
    required String position,
  }) async {
    final res = await _withAuthRetry(() async {
      return http.patch(
        Uri.parse('$baseUrl/employees/$id/'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'position': position,
        }),
      );
    });

    if (res.statusCode != 200) {
      throw Exception('Failed to update employee — ${res.statusCode}');
    }
  }

  static Future<void> deleteEmployee(int id) async {
    final res = await _withAuthRetry(() async {
      return http.delete(
        Uri.parse('$baseUrl/employees/$id/'),
        headers: await _authHeaders(),
      );
    });
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to delete employee — ${res.statusCode}');
    }
  }

  // ======================================================
  // 💳 SUBSCRIPTIONS (Owner)
  // ======================================================
  static Future<List<dynamic>> getPlans() async {
    final res = await _withAuthRetry(() async {
      return http.get(
        Uri.parse("$baseUrl/subscriptions/plans/"),
        headers: await _authHeaders(),
      );
    });
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load plans: ${res.statusCode}");
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
      return null;
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
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Failed to load payments: ${res.statusCode}");
  }
}
