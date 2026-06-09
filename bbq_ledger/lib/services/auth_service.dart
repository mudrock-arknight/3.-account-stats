// lib/services/auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<AppUser>> getUsers() async {
    debugPrint('[AuthService] getUsers called, URL=${SupabaseConfig.url}');
    try {
      final response = await _client.from('users').select();
      debugPrint('[AuthService] getUsers response type=${response.runtimeType}');
      return (response as List).map((e) => AppUser.fromJson(e)).toList();
    } catch (e, st) {
      debugPrint('[AuthService] getUsers ERROR: $e');
      debugPrint('[AuthService] StackTrace: $st');
      rethrow;
    }
  }

  Future<AppUser?> login(String userId, String pin) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .eq('pin_code', pin)
        .maybeSingle();

    if (response == null) return null;
    return AppUser.fromJson(response);
  }

  Future<AppUser> createUser(String name, String pinCode, String avatarColor) async {
    final response = await _client.from('users').insert({
      'name': name,
      'pin_code': pinCode,
      'avatar_color': avatarColor,
    }).select().single();

    return AppUser.fromJson(response);
  }
}