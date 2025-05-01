import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snack_hunt/config.dart';
import '../models/snack.dart';
import '../config.dart';

class ApiService {

  // Get all snacks
  Future<List<Snack>> getSnacks() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/snacks/get'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Snack.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load snacks: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching snacks: $e');
      throw Exception('Failed to load snacks: $e');
    }
  }

  Future<List<Snack>> getSnacksByUserId(int userId, String token) async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/api/snacks/user/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token', // Tambahkan header Authorization
          },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Snack.fromJson(json)).toList();
      } else {
        print('Failed to load snacks: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching snacks by user ID: $e');
      throw Exception('Failed to load snacks by user ID: $e');
    }
  }

  // Get snacks by category
  Future<List<Snack>> getSnacksByCategory(String category) async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/api/snacks/get?type=$category')
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Snack.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load snacks by category: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching snacks by category: $e');
      throw Exception('Failed to load snacks by category: $e');
    }
  }
  Future<Snack> updateSnack(Snack snack, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/snacks/${snack.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(snack.toJson()),
      );

      if (response.statusCode == 200) {
        return Snack.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update snack: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating snack: $e');
    }
  }

  Future<void> deleteSnack(int snackId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/snacks/$snackId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete snack: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting snack: $e');
    }
  }
}
