import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/user_data.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.60:3000/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Giriş başarısız: ${response.body}');
      }
    } catch (e) {
      throw Exception('Giriş yapılırken bir hata oluştu: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password, 'name': name}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Kayıt başarısız: ${response.body}');
      }
    } catch (e) {
      throw Exception('Kayıt olurken bir hata oluştu: $e');
    }
  }

  Future<String?> getToken() async {
    return await UserData.getToken();
  }

  Future<void> logout() async {
    await UserData.clearToken();
  }

  Future<String> getAdminId() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['adminId'];
      } else {
        throw Exception('Admin ID alınamadı: ${response.body}');
      }
    } catch (e) {
      throw Exception('Admin ID alınırken bir hata oluştu: $e');
    }
  }
}
