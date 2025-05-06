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

  Future<Favorite> addFavorite(int userId, int snackId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/favorities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'snackId': snackId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return Favorite.fromJson(jsonData);
      } else {
        throw Exception('Failed to add favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding favorite: $e');
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> deleteFavorite(int favoriteId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/favorities/$favoriteId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting favorite: $e');
      throw Exception('Failed to delete favorite: $e');
    }
  }
}