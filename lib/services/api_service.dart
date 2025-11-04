import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drink_model.dart';
import '../utils/constants.dart';

class ApiService {
  Future<List<Drink>> fetchDrinks() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['drinks'] ?? [];
      return data.map((e) => Drink.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load drinks');
    }
  }
}
