import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:snack_hunt/config.dart';
import 'package:http_parser/http_parser.dart';
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

  Future<Snack> getSnackById(int snackId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/snacks/get/$snackId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final snack = Snack.fromJson(jsonData);
        return snack;
      } else {
        throw Exception('Failed to load snack: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching snack by ID: $e');
      throw Exception('Failed to load snack by ID: $e');
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

  // Add a new snack
  Future<Snack> addSnack(Snack snack, String token) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/snacks');
    final request = http.MultipartRequest('POST', uri);

    // Tambahkan header Authorization
    request.headers['Authorization'] = 'Bearer $token';

    // Tambahkan field-field
    request.fields['name'] = Uri.encodeComponent(snack.name);
    request.fields['price'] = snack.price.toInt().toString();
    request.fields['seller'] = Uri.encodeComponent(snack.seller);
    request.fields['contact'] = Uri.encodeComponent(snack.contact);
    request.fields['location'] = Uri.encodeComponent(snack.location);
    request.fields['rating'] = snack.rating.toString();
    request.fields['type'] = snack.type;
    request.fields['userId'] = snack.userId.toString();

    // Tambahkan file image
    final bytes = base64Decode(snack.image);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: 'snack_image.jpg',
      contentType: MediaType('image', 'jpeg'), // atau 'png' jika file PNG
    ));

    // Kirim request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Snack.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add snack: ${response.statusCode} ${response.body}');
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
