import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ouro_pay_consumer_app/services/kyc_service.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:ouro_pay_consumer_app/theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/widgets/app_button.dart';

class KycStatusPage extends StatefulWidget {
  final KycData kycData;

  const KycStatusPage({super.key, required this.kycData});

  @override
  State<KycStatusPage> createState() => _KycStatusPageState();
}

class _KycStatusPageState extends State<KycStatusPage> {
  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  // Resubmission files
  File? _documentFront;
  File? _documentBack;
  File? _selfie;

  bool _isResubmitting = false;

  Future<void> _pickImage(String type) async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (type == 'front')
          _documentFront = File(image.path);
        else if (type == 'back')
          _documentBack = File(image.path);
        else if (type == 'selfie') _selfie = File(image.path);
      });
    }
  }

  Future<void> _handleResubmit() async {
    if (_documentFront == null && _documentBack == null && _selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one document')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await KycService().resubmitKyc(
      documentFront: _documentFront,
      documentBack: _documentBack,
      selfie: _selfie,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('KYC resubmitted successfully')),
        );

        // Refresh status - effectively reloading the page logic
        // For now, simpler to navigate back to splash to re-check status
        Navigator.of(context).pushReplacementNamed('/splash');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resubmit KYC')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isResubmitting) {
      return _buildResubmissionForm();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('KYC Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusIcon(),
            const SizedBox(height: 24),
            _buildStatusMessage(),
            const SizedBox(height: 16),
            if (widget.kycData.status == 'rejected') ...[
              _buildRejectionDetails(),
              const SizedBox(height: 24),
              if (widget.kycData.canResubmit)
                AppButton(
                  text: 'Resubmit KYC Information',
                  onPressed: () {
                    // Fetch requirements first?
                    // For simplicity, just show upload form
                    setState(() => _isResubmitting = true);
                  },
                )
              else
                const Text(
                  'No more resubmissions allowed.',
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (widget.kycData.status) {
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'pending':
      case 'under_review':
      default:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
    }

    return Icon(icon, size: 80, color: color);
  }

  Widget _buildStatusMessage() {
    String title;
    String description;

    switch (widget.kycData.status) {
      case 'pending':
      case 'under_review':
        title = 'KYC in Progress';
        description = 'Your KYC is being processed. Please wait.';
        break;
      case 'rejected':
        title = 'KYC Rejected';
        description = 'Your verification was rejected.';
        break;
      case 'approved':
        title = 'Verified';
        description = 'Your account is verified.';
        break;
      default:
        title = 'Status: ${widget.kycData.status}';
        description = '';
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRejectionDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (widget.kycData.rejectionReason != null)
            Text(
              'Reason: ${widget.kycData.rejectionReason}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          if (widget.kycData.adminNotes != null) ...[
            const SizedBox(height: 8),
            Text(
              'Note: ${widget.kycData.adminNotes}',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResubmissionForm() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resubmit Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isResubmitting = false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Please upload the required documents.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildUploadButton('Document Front', _documentFront, 'front'),
            const SizedBox(height: 16),
            _buildUploadButton('Document Back', _documentBack, 'back'),
            const SizedBox(height: 16),
            _buildUploadButton('Selfie', _selfie, 'selfie'),
            const Spacer(),
            AppButton(
              text: 'Submit',
              isLoading: _isLoading,
              onPressed: _handleResubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label, File? file, String type) {
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(file != null ? Icons.check_circle : Icons.upload_file,
                color: file != null ? Colors.green : Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                file != null ? 'File Selected' : 'Upload $label',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
