import 'dart:convert';

import 'package:map_view_taskproject/model/userModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('current_user', user.toJson().toString());
  }

  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('current_user');
    if (userString != null) {
      final Map<String, dynamic> userMap = jsonDecode(userString);
      return User.fromJson(userMap);
    }
    return null;
  }
}
