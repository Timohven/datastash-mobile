// lib/services/auth_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _usernameKey = 'username';

  // Сохранить токен после логина
  static Future<void> saveToken(String token, String username) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
  }

  // Прочитать токен (null если не залогинен)
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  // Удалить токен (logout)
  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Логин через FastAPI
  static Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/auth/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        await saveToken(token, username);
        return token;
      }
      return null; // неверный логин/пароль
    } catch (e) {
      return null; // сетевая ошибка
    }
  }

  // Проверить что токен ещё действителен (опционально — проверка через API)
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$API_URL/notes'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode != 401;
    } catch (e) {
      return false;
    }
  }
}