import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/portfolio.dart';
import 'package:ouro_pay_consumer_app/models/user.dart';
import 'package:ouro_pay_consumer_app/widgets/logo.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late UserPortfolio _portfolio;
  User _user = User(
    id: 'user_123',
    email: 'user@example.com',
    firstName: 'Guest',
    lastName: 'User',
    createdAt: DateTime.now(),
    lastLoginAt: DateTime.now(),
    isVerified: false,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _portfolio = UserPortfolio.createDefault('user_123'); // Will be updated when user loads
    // Load user data after a small delay to ensure it's available after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always reload user data when page becomes visible (e.g., after login)
    // This ensures we get the latest user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      
      print('📊 Dashboard: Loading user data');
      print('  User from storage: ${user?.displayName ?? 'null'} (${user?.email ?? 'no email'})');
      print('  Current user: ${_user.displayName} (${_user.email})');
      
      if (mounted) {
        if (user != null) {
          // Update with actual user data
          setState(() {
            _user = user;
            // Update portfolio with user ID
            _portfolio = UserPortfolio.createDefault(_user.id);
          });
          print('  ✅ Dashboard: User data updated - ${_user.displayName} (${_user.email})');
        } else {
          print('  ⚠️ Dashboard: No user data found in storage');
          // Check if we're authenticated - if yes, try to reload
          final isAuth = await authService.isAuthenticated();
          if (isAuth) {
            print('  🔄 Dashboard: User is authenticated but no data found, this might be a sync issue');
          }
        }
      }
    } catch (e) {
      print('  ❌ Dashboard: Error loading user data: $e');
      print('  Stack trace: ${StackTrace.current}');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Portfolio overview card
          _buildPortfolioOverview(),

          // Tab bar
          Container(
            color: AppColors.cardBackground,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryGold,
              labelColor: AppColors.primaryGold,
              unselectedLabelColor: AppColors.greyText,
              tabs: const [
                Tab(text: 'Wallets', icon: Icon(Icons.account_balance_wallet)),
                Tab(text: 'Gold', icon: Icon(Icons.stars)),
                Tab(text: 'Trade', icon: Icon(Icons.trending_up)),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWalletsTab(),
                _buildGoldTab(),
                _buildTradeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      title: Row(
        children: [
          // Logo
          const OuroPayIcon(size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OUROPAY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              Text(
                'Welcome back, ${_user.firstName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Gold points display
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.stars,
                size: 16,
                color: AppColors.darkBackground,
              ),
              const SizedBox(width: 4),
              Text(
                _portfolio.goldHolding.formattedGrams,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBackground,
                ),
              ),
            ],
          ),
        ),

        // Profile menu
        IconButton(
          onPressed: _showProfileMenu,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryGold,
            child: Text(
              _user.initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBackground,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioOverview() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Value',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.visibility,
                color: AppColors.darkBackground.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_portfolio.totalPortfolioValue.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBackground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+\$0.00 (0.00%) today',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBackground.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Your Wallets',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.whiteText,
          ),
        ),
        const SizedBox(height: 16),

        // Wallets
        ..._portfolio.wallets.map((wallet) => _buildWalletCard(wallet)),

        const SizedBox(height: 20),

        // Quick actions
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.whiteText,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add,
                label: 'Add Money',
                onPressed: () => _showComingSoon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.send,
                label: 'Send Money',
                onPressed: () => _showComingSoon(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoldTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Gold holdings card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gold Holdings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.whiteText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\$${_portfolio.goldHolding.currentPricePerGram.toStringAsFixed(2)}/g',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBackground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: AppColors.primaryGold,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _portfolio.goldHolding.formattedGrams,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.whiteText,
                          ),
                        ),
                        Text(
                          _portfolio.goldHolding.formattedValue,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Gold actions
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_shopping_cart,
                label: 'Buy Gold',
                onPressed: () => Navigator.pushNamed(context, '/trade'),
                backgroundColor: AppColors.successGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.sell,
                label: 'Sell Gold',
                onPressed: () => Navigator.pushNamed(context, '/trade'),
                backgroundColor: AppColors.errorRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTradeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Gold Trading',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.whiteText,
          ),
        ),
        const SizedBox(height: 16),

        // Market info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gold Price (USD)',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.greyText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+2.3%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\$${_portfolio.goldHolding.currentPricePerGram.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.whiteText,
                      ),
                    ),
                    const Text(
                      ' per gram',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Trading actions
        _buildActionButton(
          icon: Icons.swap_horiz,
          label: 'Start Trading',
          onPressed: () => Navigator.pushNamed(context, '/trade'),
          isFullWidth: true,
        ),

        const SizedBox(height: 12),

        _buildActionButton(
          icon: Icons.history,
          label: 'Transaction History',
          onPressed: () => Navigator.pushNamed(context, '/transactions'),
          isFullWidth: true,
          backgroundColor: AppColors.cardBackground,
          textColor: AppColors.primaryGold,
        ),
      ],
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    Color currencyColor;
    switch (wallet.currency) {
      case 'USD':
        currencyColor = AppColors.usdColor;
        break;
      case 'EUR':
        currencyColor = AppColors.euroColor;
        break;
      case 'SRD':
        currencyColor = AppColors.srdColor;
        break;
      default:
        currencyColor = AppColors.primaryGold;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: currencyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: currencyColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.whiteText,
                      ),
                    ),
                    Text(
                      wallet.currency,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    wallet.formattedAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteText,
                    ),
                  ),
                  Text(
                    '≈ \$${wallet.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryGold,
          foregroundColor: textColor ?? AppColors.darkBackground,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.primaryGold),
              title: const Text('Profile',
                  style: TextStyle(color: AppColors.whiteText)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.primaryGold),
              title: const Text('Settings',
                  style: TextStyle(color: AppColors.whiteText)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: AppColors.primaryGold),
              title: const Text('Help & Support',
                  style: TextStyle(color: AppColors.whiteText)),
              onTap: () => _showComingSoon(),
            ),
            const Divider(color: AppColors.greyText),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.errorRed),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.errorRed)),
              onTap: () => _handleLogout(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context); // Close bottom sheet
    
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Logout',
          style: TextStyle(color: AppColors.whiteText),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.greyText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryGold,
          ),
        ),
      );

      try {
        final authService = AuthService();
        final success = await authService.logout();

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog

          if (success) {
            // Navigate to welcome page and clear navigation stack
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (route) => false,
            );

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: AppColors.primaryGold,
              ),
            );
          } else {
            // Even if logout API failed, still navigate to welcome
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Still navigate to welcome even if there's an error
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/welcome',
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout completed: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon!'),
        backgroundColor: AppColors.primaryGold,
      ),
    );
  }
}
