import 'package:shared_preferences/shared_preferences.dart';

class TestPreferences {
  static const _key = 'test_minutes';

  static Future<int> getTestMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<void> setTestMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, minutes);
  }
}
