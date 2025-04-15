// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  Employee? _currentUser;

  Employee? get currentUser => _currentUser;

  Future<void> loadCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt("userId");
    if (userId != null) {
      try {
        _currentUser = await ApiService.fetchEmployee(userId);
      } catch (e) {
        _currentUser = null;
      }
      notifyListeners();
    }
  }

  Future<void> setUser(Employee user) async {
    _currentUser = user;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("userId", user.id);
    await prefs.setBool("isLoggedIn", true);
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("userId");
    await prefs.remove("isLoggedIn");
    notifyListeners();
  }

  void updateUser(Employee updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }
}
