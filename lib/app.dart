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

class OuroPayApp extends StatefulWidget {
  const OuroPayApp({super.key});

  @override
  State<OuroPayApp> createState() => _OuroPayAppState();
}

class _OuroPayAppState extends State<OuroPayApp> {
  String? _initialRoute;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndSetInitialRoute();
  }

  Future<void> _checkAuthenticationAndSetInitialRoute() async {
    try {
      final authService = AuthService();
      final isAuthenticated = await authService.isAuthenticated();
      
      if (mounted) {
        setState(() {
          _initialRoute = isAuthenticated ? '/dashboard' : '/welcome';
          _isCheckingAuth = false;
        });
        print('🔒 App: Authentication check complete - ${isAuthenticated ? "Authenticated" : "Not authenticated"}');
        print('🔒 App: Initial route set to: $_initialRoute');
      }
    } catch (e) {
      print('⚠️ App: Error checking authentication: $e');
      if (mounted) {
        setState(() {
          _initialRoute = '/welcome';
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking authentication
    if (_isCheckingAuth || _initialRoute == null) {
      return MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: AppConfig.isDebugMode,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGold,
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: AppConfig.isDebugMode,
      theme: AppTheme.darkTheme,
      initialRoute: _initialRoute ?? '/welcome',
      onGenerateRoute: (settings) {
        // Handle authentication-protected routes
        final routeName = settings.name;
        
        // Routes that require authentication
        final protectedRoutes = ['/dashboard', '/portfolio', '/trade', '/transactions', '/settings', '/profile'];
        
        // Routes that should redirect to dashboard if authenticated
        final authRoutes = ['/login', '/signup', '/welcome'];
        
        // Check if route requires authentication
        if (protectedRoutes.contains(routeName)) {
          return _buildRouteWithAuthCheck(settings);
        }
        
        // Check if route should redirect authenticated users
        if (authRoutes.contains(routeName)) {
          return _buildRouteWithAuthRedirect(settings);
        }
        
        // Default route handling
        return _buildDefaultRoute(settings);
      },
    );
  }

  Route<dynamic> _buildRouteWithAuthCheck(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return FutureBuilder<bool>(
          future: AuthService().isAuthenticated(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.darkBackground,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGold,
                  ),
                ),
              );
            }
            
            if (snapshot.data == true) {
              return _getPageForRoute(settings.name ?? '/dashboard');
            } else {
              // Not authenticated, redirect to login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/login');
              });
              return const Scaffold(
                backgroundColor: AppColors.darkBackground,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGold,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Route<dynamic> _buildRouteWithAuthRedirect(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        return FutureBuilder<bool>(
          future: AuthService().isAuthenticated(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _getPageForRoute(settings.name ?? '/welcome');
            }
            
            if (snapshot.data == true) {
              // Already authenticated, redirect to dashboard
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacementNamed('/dashboard');
              });
              return const Scaffold(
                backgroundColor: AppColors.darkBackground,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGold,
                  ),
                ),
              );
            } else {
              // Not authenticated, show the page
              return _getPageForRoute(settings.name ?? '/welcome');
            }
          },
        );
      },
    );
  }

  Route<dynamic> _buildDefaultRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _getPageForRoute(settings.name ?? '/welcome'),
    );
  }

  Widget _getPageForRoute(String routeName) {
    switch (routeName) {
      case '/welcome':
        return const WelcomePage();
      case '/login':
        return const LoginPage();
      case '/signup':
        return const SignUpPage();
      case '/dashboard':
        return const DashboardPage();
      case '/portfolio':
        return const PortfolioPage();
      case '/trade':
        return const TradePage();
      case '/transactions':
        return const TransactionsPage();
      case '/settings':
        return const SettingsPage();
      case '/profile':
        return const ProfilePage();
      default:
        return const WelcomePage();
    }
  }
}
