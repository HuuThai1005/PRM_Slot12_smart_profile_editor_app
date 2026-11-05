import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_model.dart';

class DraftService {
  static const _key = 'profile_draft';

  Future<void> save(Profile profile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(profile.toJson()));
  }

  Future<Profile?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);

    if (raw == null) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return Profile.fromJson(data);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}
