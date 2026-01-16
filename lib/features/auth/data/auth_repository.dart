import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:mesh_app/features/auth/domain/user_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  static const String _fileName = 'users.json';
  static const String _sessionKey = 'auth_session_user_id';

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<void> _seedUsersIfNeeded() async {
    final file = await _file;
    if (!await file.exists()) {
      try {
        final assetContent = await rootBundle.loadString('assets/users.json');
        await file.writeAsString(assetContent);
      } catch (e) {
        // If asset not found or error, create empty or log error
        // For now, doing nothing effectively means empty user list initially until populated or error handled.
      }
    }
  }

  Future<List<AuthUser>> _readUsers() async {
    await _seedUsersIfNeeded();
    try {
      final file = await _file;
      if (!await file.exists()) {
        return [];
      }
      final content = await file.readAsString();
      if (content.isEmpty) return [];
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => AuthUser.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<AuthUser?> login(String username, String password) async {
    final users = await _readUsers();
    try {
      final user = users.firstWhere(
        (user) => user.username == username && user.password == password,
      );
      await saveSession(user.id);
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<AuthUser?> getUserById(String id) async {
    final users = await _readUsers();
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }

  Future<String?> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
  Future<bool> hasUsers() async {
     final users = await _readUsers();
     return users.isNotEmpty;
  }
}
