
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/user.dart';

class ApiUser{
  Future<User> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final user = User.fromJson(jsonData);
        return user;
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
      throw Exception('Failed to load user by ID: $e');
    }
  }
}