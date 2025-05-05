import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/favorite.dart';
import '../config.dart';

class ApiFavorite{
  Future <List<Favorite>> getFavoritesByUserId(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/favorities/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Favorite.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      throw Exception('Failed to load favorites: $e');
    }
  }
}