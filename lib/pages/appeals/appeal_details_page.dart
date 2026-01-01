import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/models/appeal.dart';
import 'package:ouro_pay_consumer_app/services/appeal_service.dart';

class AppealDetailsPage extends StatefulWidget {
  final int appealId;
  const AppealDetailsPage({super.key, required this.appealId});

  @override
  State<AppealDetailsPage> createState() => _AppealDetailsPageState();
}

class _AppealDetailsPageState extends State<AppealDetailsPage> {
  bool _isLoading = true;
  Appeal? _appeal;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppealDetails();
  }

  Future<void> _fetchAppealDetails() async {
    setState(() => _isLoading = true);
    final response = await AppealService().getAppealDetails(widget.appealId);
    if (mounted) {
      setState(() {
        _appeal = response.data;
        if (!response.success) {
          _error = response.message;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Appeal Details'),
        backgroundColor: AppColors.darkBackground,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
          : _error != null || _appeal == null
              ? Center(
                  child: Text(_error ?? 'Appeal not found',
                      style: const TextStyle(color: AppColors.errorRed)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _appeal!.subject,
                                    style: const TextStyle(
                                      color: AppColors.whiteText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_appeal!.status)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color:
                                            _getStatusColor(_appeal!.status)),
                                  ),
                                  child: Text(
                                    _appeal!.statusLabel,
                                    style: TextStyle(
                                        color: _getStatusColor(_appeal!.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Created at: ${_formatDate(_appeal!.createdAt)}',
                              style: const TextStyle(
                                  color: AppColors.greyText, fontSize: 12),
                            ),
                            const Divider(color: AppColors.greyText),
                            const SizedBox(height: 8),
                            const Text(
                              'Details',
                              style: TextStyle(
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _appeal!.appealDetails,
                              style:
                                  const TextStyle(color: AppColors.whiteText),
                            ),
                            if (_appeal!.additionalNotes != null &&
                                _appeal!.additionalNotes!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Additional Notes',
                                style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _appeal!.additionalNotes!,
                                style:
                                    const TextStyle(color: AppColors.whiteText),
                              ),
                            ],
                            if (_appeal!.adminResponse != null) ...[
                              const SizedBox(height: 24),
                              const Divider(color: AppColors.greyText),
                              const SizedBox(height: 8),
                              const Text(
                                'Admin Response',
                                style: TextStyle(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _appeal!.adminResponse!,
                                style:
                                    const TextStyle(color: AppColors.whiteText),
                              ),
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
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
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
    } catch (_) {
      return dateStr;
    }
  }
}
