import 'package:flutter/material.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/services/appeal_service.dart';

class SubmitAppealPage extends StatefulWidget {
  const SubmitAppealPage({super.key});

  @override
  State<SubmitAppealPage> createState() => _SubmitAppealPageState();
}

class _SubmitAppealPageState extends State<SubmitAppealPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController =
      TextEditingController(text: "Need to get Back the account");
  final _detailsController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AppealService().submitAppeal(
      subject: _subjectController.text,
      appealDetails: _detailsController.text,
      additionalNotes:
          _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appeal submitted successfully')),
        );
        Navigator.pop(context); // Go back or to Appeal History
        // Optionally redirect to history
        Navigator.pushReplacementNamed(context, '/appeals');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ??
                  'Failed to submit appeal. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Submit Appeal'),
        backgroundColor: AppColors.darkBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/appeals'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: const TextStyle(color: AppColors.greyText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: AppColors.whiteText),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: 'Appeal Details',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: const TextStyle(color: AppColors.greyText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(color: AppColors.whiteText),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 20) {
                    return 'Please enter at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  labelStyle: const TextStyle(color: AppColors.greyText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(color: AppColors.whiteText),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAppeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Submit Appeal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
