import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/profile_model.dart';

class ApiService {
  final _uri = Uri.parse('https://jsonplaceholder.typicode.com/users/1');

  Future<Profile> fetchProfile() async {
    final response = await http.get(_uri).timeout(const Duration(seconds: 10));

    print('GET $_uri -> ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không tải được hồ sơ (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Profile.fromJson(data);
  }

  Future<void> updateProfile(Profile profile) async {
    final response = await http
        .put(
          _uri,
          body: jsonEncode(profile.toJson()),
          headers: const {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    print('PUT $_uri -> ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cập nhật thất bại (${response.statusCode})');
    }
  }
}
