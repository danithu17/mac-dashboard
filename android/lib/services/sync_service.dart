import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  static const String defaultServerUrl = 'http://192.168.8.184:3000';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('server_url') ?? defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', url);
  }

  // Fetch data for user from Cost-Free Backend API
  static Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    try {
      final baseUrl = await getServerUrl();
      final response = await http.get(Uri.parse('$baseUrl/api/sync/$uid'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      // Offline fallback
    }
    return null;
  }

  // Push local updates to Cost-Free Backend API
  static Future<bool> pushUserData(String uid, Map<String, dynamic> userData, Map<String, dynamic> userProfile) async {
    try {
      final baseUrl = await getServerUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'user': userProfile,
          'data': userData,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
