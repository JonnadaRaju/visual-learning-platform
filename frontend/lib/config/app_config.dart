import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AppConfig {
  AppConfig._();

  static final AppConfig instance = AppConfig._();
  static const String apiBaseUrl = 'https://eduviz-backend-xm7b.onrender.com';
  static const String sessionKey = 'session_id';
  static const String selectedClassKey = 'selected_class';

  late final SharedPreferences _prefs;
  late final String sessionId;
  int? selectedClass;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    sessionId = _prefs.getString(sessionKey) ?? const Uuid().v4();
    selectedClass = _prefs.getInt(selectedClassKey);
    await _prefs.setString(sessionKey, sessionId);
  }

  Future<void> setSelectedClass(int value) async {
    selectedClass = value;
    await _prefs.setInt(selectedClassKey, value);
  }
}