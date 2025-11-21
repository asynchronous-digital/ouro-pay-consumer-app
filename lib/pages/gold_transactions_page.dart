
import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/services/gold_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class GoldTransactionsPage extends StatefulWidget {
  const GoldTransactionsPage({Key? key}) : super(key: key);

  @override
  State<GoldTransactionsPage> createState() => _GoldTransactionsPageState();
}

class _GoldTransactionsPageState extends State<GoldTransactionsPage> {
  bool _isLoading = false;
  GoldTransactionsResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final service = GoldService();
    final resp = await service.getGoldTransactions();
    if (mounted) {
      setState(() {
        _response = resp;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gold Transactions'),
        backgroundColor: AppColors.darkBackground,
      ),
      backgroundColor: AppColors.darkBackground,
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        color: AppColors.primaryGold,
        backgroundColor: AppColors.cardBackground,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _response == null ||
                    !_response!.success ||
                    _response!.data == null ||
                    _response!.data!.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_edu,
                          size: 80,
                          color: AppColors.primaryGold.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No Transactions Yet',
                          style: TextStyle(
                            color: AppColors.whiteText,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your gold trading history will appear here',
                          style: TextStyle(
                            color: AppColors.greyText.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _response!.data!.length,
                    itemBuilder: (context, index) {
                      final item = _response!.data![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(item.toString()),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
