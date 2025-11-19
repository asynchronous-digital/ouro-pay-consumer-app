import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/models/user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data if not already loaded or if user is null
    if (_user == null && !_isLoading) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      
      print('👤 Profile: Loading user data');
      print('  User: ${user?.displayName ?? 'null'} (${user?.email ?? 'no email'})');
      
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        print('  ✅ Profile: User data loaded - ${user?.displayName ?? 'null'}');
      }
    } catch (e) {
      print('  ❌ Profile: Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.whiteText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primaryGold,
                            child: _user != null && _user!.initials.isNotEmpty
                                ? Text(
                                    _user!.initials,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkBackground,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: AppColors.darkBackground,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.displayName ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _user?.email ?? 'No email',
                                  style: const TextStyle(
                                    color: AppColors.greyText,
                                  ),
                                ),
                                if (_user?.isVerified == true) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: AppColors.successGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // User details section
                  if (_user != null) ...[
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.whiteText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.email,
                              color: AppColors.primaryGold,
                            ),
                            title: const Text('Email'),
                            subtitle: Text(_user!.email),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: AppColors.primaryGold,
                            ),
                            title: const Text('Name'),
                            subtitle: Text(_user!.displayName),
                          ),
                          if (_user!.firstName.isNotEmpty &&
                              _user!.lastName.isNotEmpty) ...[
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.badge,
                                color: AppColors.primaryGold,
                              ),
                              title: const Text('First Name'),
                              subtitle: Text(_user!.firstName),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.badge_outlined,
                                color: AppColors.primaryGold,
                              ),
                              title: const Text('Last Name'),
                              subtitle: Text(_user!.lastName),
                            ),
                          ],
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.calendar_today,
                              color: AppColors.primaryGold,
                            ),
                            title: const Text('Member Since'),
                            subtitle: Text(
                              '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.greyText),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.logout, color: AppColors.errorRed),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                      subtitle: const Text('Sign out of your account'),
                      onTap: () => _handleLogout(context),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
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
        await authService.logout();

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog

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
}
