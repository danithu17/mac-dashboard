import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  // Live Vercel zero-cost sync cloud server as default
  static const String defaultServerUrl = 'https://mac-dashboard-mu.vercel.app';
  static const Duration requestTimeout = Duration(seconds: 8);

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url') ?? defaultServerUrl;
  }

  static Future<bool> setServerUrl(String url) async {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    // Security: Validate URL format and allowed protocols
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https')) || uri.host.isEmpty) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', trimmed);
    return true;
  }

  static Future<String> getActiveUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_uid') ?? 'usr_default';
  }

  static Future<void> setActiveUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_uid', uid);
  }

  // Security: Sanitize UID
  static bool isValidUid(String uid) {
    if (uid.isEmpty || uid.length > 64) return false;
    if (uid == '__proto__' || uid == 'constructor' || uid == 'prototype') return false;
    return RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(uid);
  }

  // Fetch all accounts across Web, Desktop, and Android
  static Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    try {
      final baseUrl = await getServerUrl();
      final uri = Uri.parse('$baseUrl/api/users');
      final response = await http.get(uri).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['users'] is List) {
          return (decoded['users'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {
      // Offline fallback
    }
    return [];
  }

  // Register or sync user profile across devices
  static Future<bool> createOrUpdateUser(Map<String, dynamic> userProfile) async {
    try {
      final baseUrl = await getServerUrl();
      final uri = Uri.parse('$baseUrl/api/users');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'X-Requested-With': 'PulseHabit-Android'
        },
        body: jsonEncode({'user': userProfile}),
      ).timeout(requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Fetch data for specific user from Backend API
  static Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    if (!isValidUid(uid)) return null;

    try {
      final baseUrl = await getServerUrl();
      final uri = Uri.parse('$baseUrl/api/sync/$uid');
      final response = await http.get(uri).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
          return data['data'];
        }
      }
    } catch (_) {
      // Offline fallback
    }
    return null;
  }

  // Push local updates to Cost-Free Backend API
  static Future<bool> pushUserData(String uid, Map<String, dynamic> userData, Map<String, dynamic> userProfile) async {
    if (!isValidUid(uid)) return false;

    try {
      final baseUrl = await getServerUrl();
      final uri = Uri.parse('$baseUrl/api/sync/$uid');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'X-Requested-With': 'PulseHabit-Android'
        },
        body: jsonEncode({
          'uid': uid,
          'user': userProfile,
          'data': userData,
        }),
      ).timeout(requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
