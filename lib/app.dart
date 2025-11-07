import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/config/app_config.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/pages/welcome_page.dart';
import 'package:ouro_pay_consumer_app/pages/login_page.dart';
import 'package:ouro_pay_consumer_app/pages/dashboard_page.dart';

class OuroPayApp extends StatelessWidget {
  const OuroPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.isDebugMode,
      theme: AppTheme.darkTheme,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
