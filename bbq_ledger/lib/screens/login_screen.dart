// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppUser? _selectedUser;
  final _pinController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_selectedUser == null) {
      setState(() => _error = '请先选择用户');
      return;
    }
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = '请输入 PIN 码');
      return;
    }

    final error = await context.read<AuthProvider>().login(_selectedUser!.id, pin);
    if (error != null) {
      setState(() => _error = error);
    } else if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.outdoor_grill, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text('记账本', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 40),

              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: auth.users.map((user) {
                      final selected = _selectedUser?.id == user.id;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedUser = user;
                          _error = null;
                        }),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: selected
                                  ? Colors.orange
                                  : Color(int.parse(user.avatarColor.replaceFirst('#', '0xFF'))),
                              child: Text(
                                user.name[0],
                                style: const TextStyle(fontSize: 24, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(user.name, style: TextStyle(
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? Colors.orange : null,
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'PIN 码',
                  border: OutlineInputBorder(),
                  counterText: '',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _doLogin(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _doLogin,
                  child: const Text('登录', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}