import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/portfolio.dart';
import 'package:ouro_pay_consumer_app/models/user.dart';
import 'package:ouro_pay_consumer_app/widgets/logo.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/services/wallet_service.dart';
import 'package:ouro_pay_consumer_app/services/gold_service.dart';
import 'package:ouro_pay_consumer_app/pages/add_money_page.dart';
import 'package:ouro_pay_consumer_app/pages/deposit_history_page.dart';
import 'package:ouro_pay_consumer_app/utils/debug_prefs.dart';
import 'package:shimmer/shimmer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late UserPortfolio _portfolio;
  late User _user;
  bool _isLoadingWallets = false; // Loading state for wallets
  bool _isLoadingGold = false; // Loading state for gold holdings
  Map<String, double>? _goldCurrentValues; // Gold values by currency
  double? _totalGoldGrams; // Total gold in grams
  bool _isLoadingGoldPrice = false; // Loading state for gold price
  GoldPriceData? _goldPriceData; // Current gold price data
  String _selectedCurrency = 'EUR'; // Currently selected currency for price

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _portfolio = UserPortfolio.createDefault(
        'user_123'); // Will be updated when user loads
    _loadUserData();
    _loadGoldPrice(); // Load gold price for EUR by default
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data if user is still default/guest (e.g., after login)
    // This ensures user data is refreshed when navigating from login
    try {
      if (_user.firstName == 'Guest' && _user.email == 'user@example.com') {
        _loadUserData();
      }
    } catch (e) {
      // If _user is not initialized yet, load it
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Debug: Print all saved SharedPreferences data
      await DebugPrefs.printAllSavedData();

      final authService = AuthService();
      final user = await authService.getCurrentUser();

      print('📊 Dashboard: Loading user data');
      print(
          '  User: ${user?.displayName ?? 'null'} (${user?.email ?? 'no email'})');

      if (mounted) {
        setState(() {
          _user = user ??
              User(
                id: 'user_123',
                email: 'user@example.com',
                firstName: 'Guest',
                lastName: 'User',
                createdAt: DateTime.now(),
                lastLoginAt: DateTime.now(),
                isVerified: false,
              );
          // Update portfolio with user ID
          _portfolio = UserPortfolio.createDefault(_user.id);
        });
        print('  ✅ Dashboard: User data loaded - ${_user.displayName}');

        // Load wallet data and gold holdings after user is loaded
        _loadWalletData();
        _loadGoldHoldings();
      }
    } catch (e) {
      print('  ❌ Dashboard: Error loading user data: $e');
      // Fallback to default user if loading fails
      if (mounted) {
        setState(() {
          _user = User(
            id: 'user_123',
            email: 'user@example.com',
            firstName: 'Guest',
            lastName: 'User',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            isVerified: false,
          );
          _portfolio = UserPortfolio.createDefault(_user.id);
        });
      }
    }
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoadingWallets = true;
    });

    try {
      print('💰 Dashboard: Loading wallet data');
      final authService = AuthService();
      final token = await authService.getToken();
      print('=' * 80);
      print('ACCESS TOKEN FOR POSTMAN:');
      print(token);
      print('=' * 80);

      // Also write to file for easy retrieval
      try {
        final file = File('/tmp/access_token.txt');
        await file.writeAsString('ACCESS TOKEN:\n$token\n');
        print('✅ Token written to /tmp/access_token.txt');
      } catch (e) {
        print('⚠️ Could not write token to file: $e');
      }
      final walletService = WalletService();
      final response = await walletService.getWallets();

      if (mounted) {
        if (response.success && response.wallets != null) {
          // Convert API wallet data to app Wallet model
          final wallets = response.wallets!.map((apiWallet) {
            return Wallet(
              currency: apiWallet.currencyCode,
              amount: apiWallet.availableBalance,
              symbol: apiWallet.currencySymbol,
              displayName: apiWallet.currencyName,
              hasError: false,
            );
          }).toList();

          setState(() {
            _portfolio = _portfolio.copyWith(
              wallets: wallets,
              lastUpdated: DateTime.now(),
            );
            _isLoadingWallets = false;
          });
          print('  ✅ Dashboard: ${wallets.length} wallets loaded successfully');
        } else {
          // On error, mark wallets as having errors (will show N/A)
          print('  ⚠️ Dashboard: Failed to load wallets - ${response.message}');
          final errorWallets = _portfolio.wallets.map((wallet) {
            return wallet.copyWith(hasError: true);
          }).toList();

          setState(() {
            _portfolio = _portfolio.copyWith(
              wallets: errorWallets,
              lastUpdated: DateTime.now(),
            );
            _isLoadingWallets = false;
          });
        }
      }
    } catch (e) {
      print('  ❌ Dashboard: Error loading wallet data: $e');
      // On error, mark wallets as having errors (will show N/A)
      if (mounted) {
        final errorWallets = _portfolio.wallets.map((wallet) {
          return wallet.copyWith(hasError: true);
        }).toList();

        setState(() {
          _portfolio = _portfolio.copyWith(
            wallets: errorWallets,
            lastUpdated: DateTime.now(),
          );
          _isLoadingWallets = false;
        });
      }
    }
  }

  Future<void> _loadGoldHoldings() async {
    setState(() {
      _isLoadingGold = true;
    });

    try {
      print('🪙 Dashboard: Loading gold holdings');
      final goldService = GoldService();
      final response = await goldService.getGoldHoldings();

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _goldCurrentValues = response.data!.currentValues;
            _totalGoldGrams = response.data!.totalGrams;
            _isLoadingGold = false;
          });
          print(
              '  ✅ Dashboard: Gold holdings loaded - ${_totalGoldGrams} grams');
        } else {
          // On error, set to null (will show N/A)
          print(
              '  ⚠️ Dashboard: Failed to load gold holdings - ${response.message}');
          setState(() {
            _goldCurrentValues = null;
            _totalGoldGrams = null;
            _isLoadingGold = false;
          });
        }
      }
    } catch (e) {
      print('  ❌ Dashboard: Error loading gold holdings: $e');
      // On error, set to null (will show N/A)
      if (mounted) {
        setState(() {
          _goldCurrentValues = null;
          _totalGoldGrams = null;
          _isLoadingGold = false;
        });
      }
    }
  }

  Future<void> _loadGoldPrice({String? currency}) async {
    setState(() {
      _isLoadingGoldPrice = true;
    });

    try {
      final cur = currency ?? _selectedCurrency;
      print('💰 Dashboard: Loading gold price for $cur');
      final goldService = GoldService();
      final response = await goldService.getGoldPrice(cur);

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _goldPriceData = response.data;
            _isLoadingGoldPrice = false;
          });
          print(
              '  ✅ Dashboard: Gold price loaded - Buy: ${_goldPriceData!.buyPrice}, Sell: ${_goldPriceData!.sellPrice}');
        } else {
          // On error, set to null
          print(
              '  ⚠️ Dashboard: Failed to load gold price - ${response.message}');
          setState(() {
            _goldPriceData = null;
            _isLoadingGoldPrice = false;
          });
        }
      }
    } catch (e) {
      print('  ❌ Dashboard: Error loading gold price: $e');
      // On error, set to null
      if (mounted) {
        setState(() {
          _goldPriceData = null;
          _isLoadingGoldPrice = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    // Refresh all data
    await Future.wait([
      _loadUserData(),
      _loadWalletData(),
      _loadGoldHoldings(),
      _loadGoldPrice(),
    ]);
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
      child: _isLoadingWallets
          ? _buildShimmerPortfolio()
          : Column(
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

  Widget _buildShimmerPortfolio() {
    return Shimmer.fromColors(
      baseColor: AppColors.darkBackground.withOpacity(0.3),
      highlightColor: AppColors.darkBackground.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.darkBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerWalletCard({required Color iconColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Shimmer.fromColors(
          baseColor: AppColors.cardBackground.withOpacity(0.6),
          highlightColor: AppColors.cardBackground.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon placeholder with currency color
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display name placeholder
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.greyText,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Currency placeholder
                      Container(
                        width: 60,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.greyText,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Amount placeholder
                    Container(
                      width: 80,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.greyText,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // USD equivalent placeholder
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.greyText,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Arrow placeholder
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.greyText.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryGold,
      backgroundColor: AppColors.cardBackground,
      child: ListView(
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
          if (_isLoadingWallets) ...[
            _buildShimmerWalletCard(iconColor: AppColors.euroColor),
            _buildShimmerWalletCard(iconColor: AppColors.usdColor),
            _buildShimmerWalletCard(iconColor: AppColors.srdColor),
          ] else
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
                  onPressed: _showAddMoneyDialog,
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
      ),
    );
  }

  Widget _buildGoldTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryGold,
      backgroundColor: AppColors.cardBackground,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gold holdings card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gold Holdings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total grams
                  Row(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: AppColors.primaryGold,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoadingGold
                                ? 'Loading...'
                                : _totalGoldGrams != null
                                    ? '${_totalGoldGrams!.toStringAsFixed(3)} g'
                                    : 'N/A',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.whiteText,
                            ),
                          ),
                          const Text(
                            'Total Gold',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.greyText),
                  const SizedBox(height: 16),

                  // Currency selector and price display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Currency dropdown
                      DropdownButton<String>(
                        value: _selectedCurrency,
                        items: ['EUR', 'USD', 'SRD']
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCurrency = val;
                            });
                            _loadGoldPrice(currency: val);
                          }
                        },
                      ),
                      // Price display
                      _isLoadingGoldPrice
                          ? const CircularProgressIndicator()
                          : _goldPriceData != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Buy: ${_goldPriceData!.getFormattedBuyPrice()}',
                                      style: const TextStyle(
                                          color: AppColors.successGreen),
                                    ),
                                    Text(
                                      'Sell: ${_goldPriceData!.getFormattedSellPrice()}',
                                      style: const TextStyle(
                                          color: AppColors.errorRed),
                                    ),
                                  ],
                                )
                              : const Text('Select a currency'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Currency values (existing)
                  const Text(
                    'Value by Currency',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // EUR
                  _buildCurrencyValueRow(
                    'EUR',
                    '€',
                    AppColors.euroColor,
                  ),
                  const SizedBox(height: 12),

                  // USD
                  _buildCurrencyValueRow(
                    'USD',
                    '\$',
                    AppColors.usdColor,
                  ),
                  const SizedBox(height: 12),

                  // SRD
                  _buildCurrencyValueRow(
                    'SRD',
                    'Sr\$',
                    AppColors.srdColor,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Gold actions
        ],
      ),
    );
  }

  Widget _buildCurrencyValueRow(String currency, String symbol, Color color) {
    String displayValue;

    if (_isLoadingGold) {
      displayValue = 'Loading...';
    } else if (_goldCurrentValues != null) {
      final value = _goldCurrentValues![currency.toLowerCase()] ?? 0;
      displayValue = '$symbol${value.toStringAsFixed(2)}';
    } else {
      displayValue = 'N/A';
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currency,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.greyText,
                ),
              ),
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeTab() {
    final String displayCurrency = _goldPriceData?.currency ?? 'EUR';
    final String buyPrice = _isLoadingGoldPrice
        ? 'Loading...'
        : _goldPriceData?.getFormattedBuyPrice() ?? 'N/A';
    final String sellPrice = _isLoadingGoldPrice
        ? 'Loading...'
        : _goldPriceData?.getFormattedSellPrice() ?? 'N/A';

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryGold,
      backgroundColor: AppColors.cardBackground,
      child: ListView(
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

          // Market info card - Buy Price
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Buy Price ($displayCurrency)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      if (_goldPriceData != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${_goldPriceData!.buySpreadPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
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
                        buyPrice,
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

          const SizedBox(height: 12),

          // Sell Price Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sell Price ($displayCurrency)',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      if (_goldPriceData != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${_goldPriceData!.sellSpreadPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
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
                        sellPrice,
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
      ),
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
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DepositHistoryPage(
                  currency: wallet.currency,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.greyText,
                  size: 16,
                ),
              ],
            ),
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
              leading: const Icon(Icons.bug_report, color: AppColors.greyText),
              title: const Text('Print Token (Debug)',
                  style: TextStyle(color: AppColors.greyText)),
              onTap: () async {
                final authService = AuthService();
                final token = await authService.getToken();
                print('🔑 DEBUG TOKEN: $token');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token printed to console')),
                );
              },
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

  void _showAddMoneyDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMoneyPage(),
      ),
    );
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
