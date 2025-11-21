import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/pages/welcome_page.dart';
import 'package:ouro_pay_consumer_app/pages/login_page.dart';
import 'package:ouro_pay_consumer_app/pages/signup_page.dart';
import 'package:ouro_pay_consumer_app/pages/dashboard_page.dart';
import 'package:ouro_pay_consumer_app/pages/portfolio_page.dart';
import 'package:ouro_pay_consumer_app/pages/trade_page.dart';
import 'package:ouro_pay_consumer_app/pages/transactions_page.dart';
import 'package:ouro_pay_consumer_app/pages/settings_page.dart';
import 'package:ouro_pay_consumer_app/pages/profile_page.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/widgets/logo.dart';

class OuroPayApp extends StatelessWidget {
  const OuroPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.isDebugMode,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/portfolio': (context) => const PortfolioPage(),
        '/trade': (context) => const TradePage(),
        '/transactions': (context) => const TransactionsPage(),
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Add a small delay to show the splash screen (optional)
    await Future.delayed(const Duration(milliseconds: 1500));

    final isAuthenticated = await AuthService().isAuthenticated();

    if (mounted) {
      if (isAuthenticated) {
        // User has token - redirect to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // No token - redirect to welcome page
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            const OuroPayLogo(
              size: 150,
              showText: true,
            ),
            const SizedBox(height: 20),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
            ),
            const SizedBox(height: 20),
            // Loading text
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
