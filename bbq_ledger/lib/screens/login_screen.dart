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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadUsers();
    });
  }

  Future<void> _doLogin(AppUser user) async {
    await context.read<AuthProvider>().login(user.id);
    if (mounted) {
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
              const Icon(Icons.menu_book, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text('记账本', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('选择你的账号', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 40),

              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.loading) {
                    return const CircularProgressIndicator();
                  }
                  if (auth.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (auth.users.isEmpty) {
                    return const Text('暂无用户，请先在数据库中添加', style: TextStyle(color: Colors.grey));
                  }
                  return Wrap(
                    spacing: 16,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: auth.users.map((user) {
                      return GestureDetector(
                        onTap: () => _doLogin(user),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: Color(int.parse(user.avatarColor.replaceFirst('#', '0xFF'))),
                              child: Text(
                                user.name[0],
                                style: const TextStyle(fontSize: 28, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(user.name, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}