// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  List<AppUser> _users = [];

  AppUser? get currentUser => _currentUser;
  List<AppUser> get users => _users;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadUsers() async {
    _users = await _authService.getUsers();
    notifyListeners();
  }

  Future<String?> login(String userId, String pin) async {
    final user = await _authService.login(userId, pin);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return null;
    }
    return 'PIN 码错误，请重试';
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}