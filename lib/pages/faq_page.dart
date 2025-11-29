import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'How do I add money to my wallet?',
      'answer': 'You can add money by navigating to the Home screen and tapping on "Add Money". We support various payment methods including bank transfer and credit cards.',
    },
    {
      'question': 'How long do withdrawals take?',
      'answer': 'Withdrawals typically take 1-3 business days to process, depending on your bank.',
    },
    {
      'question': 'Is my account secure?',
      'answer': 'Yes, we use industry-standard encryption and security measures to protect your data and funds.',
    },
    {
      'question': 'How can I contact support?',
      'answer': 'You can create a support ticket directly from the Help & Support page, or email us at support@ouropay.com.',
    },
    {
      'question': 'Can I change my registered email?',
      'answer': 'For security reasons, you cannot change your email directly. Please contact support for assistance.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primaryGold,
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  _faqs[index]['question']!,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      _faqs[index]['answer']!,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
