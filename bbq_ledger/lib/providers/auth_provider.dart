// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  List<AppUser> _users = [];
  bool _loading = true;

  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => _users;
  bool get isLoggedIn => _currentUser != null;
  bool get loading => _loading;

String? _error;

  String? get error => _error;

  Future<void> loadUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _authService.getUsers();
    } catch (e) {
      _error = '加载用户失败: $e';
      _users = [];
    }
    _loading = false;
    notifyListeners();
  }Future<void> login(String userId) async {
    final user = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => _users.first,
    );
    _currentUser = user;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_user_id', userId);
  }

  Future<bool> tryAutoLogin() async {
    await loadUsers();
    if (_users.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('last_user_id');

    if (savedUserId != null) {
      final user = _users.where((u) => u.id == savedUserId).firstOrNull;
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_user_id');
  }
}