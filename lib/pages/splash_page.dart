// lib/pages/splash_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _checkLoginAndBackend();
  }

  Future<void> _checkLoginAndBackend() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool("isLoggedIn");

    await Future.delayed(const Duration(seconds: 2));

    bool backendOnline = false;
    const int maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      backendOnline = await ApiService.ping();
      if (backendOnline) break;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!backendOnline) {
      setState(() {
        errorMessage = "Server offline. Bitte bei Janiar melden. :-)";
      });
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadCurrentUser();

    if (isLoggedIn == true && userProvider.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            errorMessage,
            style: const TextStyle(fontSize: 18, color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
