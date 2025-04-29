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
}
