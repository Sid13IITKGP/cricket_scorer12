import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final currentUser = AuthService.getCurrentUser();
    if (currentUser != null && mounted) {
      // Check if user profile exists in Firestore
      try {
        final snapshot = await FirestoreService.getUser(currentUser.uid);
        final exists = snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('name');
        if (exists) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
          return;
        } else {
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
          return;
        }
      } catch (_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
        return;
      }
    }

    final user = await AuthService.signInAnonymously();
    if (!mounted) return;

    if (user != null) {
      // new anonymous user - show login to collect name/mobile
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign in. Please restart the app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🏏',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cricket Scoring',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Setting up your session...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
