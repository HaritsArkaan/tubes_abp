import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/reviewStatistic.dart';
import '../models/review.dart';

class ApiReview {
  Future <List<Review>> getReviewsByUserId(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reviews/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      throw Exception('Failed to load reviews: $e');
    }
  }

  Future<List<Review>> getReviewsBySnackId(int snackId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reviews/snack/$snackId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reviews: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      throw Exception('Failed to load reviews: $e');
    }
  }

  Future<dynamic> getReviewStatistics(int snackId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reviews/statistics/$snackId'),
      ).timeout(const Duration(seconds: 10));
      print('Review statistics API response status: ${response.statusCode}');
      print('Review statistics API response body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);
        return jsonData;
      } else {
        throw Exception('Failed to load review statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching review statistics: $e');
      throw Exception('Failed to load review statistics: $e');
    }
  }

  Future<void> createReview(Review review, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(review.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating review: $e');
      throw Exception('Failed to create review: $e');
    }
  }

  Future<void> updateReview(Review review, String token) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/reviews/${review.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(review.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating review: $e');
      throw Exception('Failed to update review: $e');
    }
  }

  Future<void> deleteReview(int reviewId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/reviews/$reviewId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete review: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting review: $e');
      throw Exception('Failed to delete review: $e');
    }
  }
}