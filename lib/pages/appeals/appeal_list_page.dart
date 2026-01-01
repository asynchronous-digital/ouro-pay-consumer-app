import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/appeal.dart';
import 'package:ouro_pay_consumer_app/services/appeal_service.dart';
import 'package:ouro_pay_consumer_app/pages/appeals/appeal_details_page.dart';

class AppealListPage extends StatefulWidget {
  const AppealListPage({super.key});

  @override
  State<AppealListPage> createState() => _AppealListPageState();
}

class _AppealListPageState extends State<AppealListPage> {
  bool _isLoading = true;
  List<Appeal> _appeals = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppeals();
  }

  Future<void> _fetchAppeals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AppealService().getAppeals();
      if (mounted) {
        setState(() {
          _appeals = response.data;
          if (!response.success) {
            _error = response.message;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
        title: const Text('Appeal History'),
        backgroundColor: AppColors.darkBackground,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
          : _error != null && _appeals.isEmpty
              ? Center(
                  child: Text('Error: $_error',
                      style: const TextStyle(color: AppColors.errorRed)))
              : _appeals.isEmpty
                  ? const Center(
                      child: Text('No appeals found.',
                          style: TextStyle(color: AppColors.greyText)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _appeals.length,
                      itemBuilder: (context, index) {
                        final appeal = _appeals[index];
                        return Card(
                          color: AppColors.cardBackground,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              appeal.subject,
                              style: const TextStyle(
                                  color: AppColors.whiteText,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  appeal.appealDetails,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: AppColors.greyText),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(appeal.status)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color:
                                                _getStatusColor(appeal.status)),
                                      ),
                                      child: Text(
                                        appeal.statusLabel,
                                        style: TextStyle(
                                            color:
                                                _getStatusColor(appeal.status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(appeal.createdAt),
                                      style: const TextStyle(
                                          color: AppColors.greyText,
                                          fontSize: 12),
                                    ),
                                  ],
                                )
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => AppealDetailsPage(
                                          appealId: appeal.id)));
                            },
                          ),
                        );
                      },
                    ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.successGreen;
      case 'rejected':
        return AppColors.errorRed;
      case 'pending':
      default:
        return AppColors.primaryGold;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }
}
