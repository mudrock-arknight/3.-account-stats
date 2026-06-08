// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/report_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

class BbqLedgerApp extends StatefulWidget {
  const BbqLedgerApp({super.key});

  @override
  State<BbqLedgerApp> createState() => _BbqLedgerAppState();
}

class _BbqLedgerAppState extends State<BbqLedgerApp> {
  bool _autoLoginChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLogin();
    });
  }

  Future<void> _tryAutoLogin() async {
    await context.read<AuthProvider>().tryAutoLogin();
    setState(() => _autoLoginChecked = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: '记账本',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.orange,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: _autoLoginChecked
            ? Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
                },
              )
            : const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}