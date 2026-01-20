import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String KEY_USER_ID = 'session_user_id';
  static const String KEY_PHONE = 'session_phone';
  static const String KEY_ROLE = 'session_role';

  /// Save session data
  static Future<void> saveSession({
    required String userId,
    required String phone,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_USER_ID, userId);
    await prefs.setString(KEY_PHONE, phone);
    await prefs.setString(KEY_ROLE, role);
    print('✅ Session saved: $userId ($role)');
  }

  /// Get current user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_USER_ID);
  }

  /// Get current role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_ROLE);
  }

  /// Get stored phone
  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_PHONE);
  }

  /// Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_USER_ID);
    await prefs.remove(KEY_PHONE);
    await prefs.remove(KEY_ROLE);
    print('✅ Session cleared');
  }
}
