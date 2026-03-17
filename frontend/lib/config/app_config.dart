import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AppConfig {
  AppConfig._();
  static final AppConfig instance = AppConfig._();
  static const String apiBaseUrl = 'http://127.0.0.1:8000';
  static const String _sessionKey = 'session_id';
  late final String sessionId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    sessionId = prefs.getString(_sessionKey) ?? const Uuid().v4();
    await prefs.setString(_sessionKey, sessionId);
  }
}
