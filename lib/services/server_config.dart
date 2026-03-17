import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _keyUrl = 'jetson_server_url';

  static Future<String> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUrl) ?? '';
  }

  static Future<void> setUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/$'), ''); // 끝 슬래시 제거
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, trimmed);
  }

  static Future<bool> isConfigured() async {
    final url = await getUrl();
    return url.isNotEmpty;
  }
}
