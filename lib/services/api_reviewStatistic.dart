import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/reviewStatistic.dart';

class ApiReviewStatistic {
  Future<ReviewStatistic> getReviewStatistics(int snackId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reviews/statistics/$snackId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        return ReviewStatistic.fromJson(jsonMap);
      } else {
        throw Exception('Failed to load review statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching review statistics: $e');
      throw Exception('Failed to load review statistics: $e');
    }
  }
}