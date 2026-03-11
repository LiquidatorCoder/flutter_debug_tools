import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsManager {
  SharedPrefsManager._privateConstructor();

  static final SharedPrefsManager _instance = SharedPrefsManager._privateConstructor();

  static SharedPrefsManager get instance => _instance;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _preferences;
    return prefs.getBool(key);
  }

  Future<bool> setBool(String key, bool value) async {
    final prefs = await _preferences;
    return prefs.setBool(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await _preferences;
    return prefs.getDouble(key);
  }

  Future<bool> setDouble(String key, double value) async {
    final prefs = await _preferences;
    return prefs.setDouble(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _preferences;
    return prefs.getInt(key);
  }

  Future<bool> setInt(String key, int value) async {
    final prefs = await _preferences;
    return prefs.setInt(key, value);
  }
}
