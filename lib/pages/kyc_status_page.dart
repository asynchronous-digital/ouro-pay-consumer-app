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
  KycRequirements? _requirements;
  bool _isLoadingRequirements = false;

  Future<void> _startResubmission() async {
    setState(() {
      _isLoadingRequirements = true;
    });

    final requirements = await KycService().getKycRequirements();

    if (mounted) {
      setState(() {
        _requirements = requirements;
        _isLoadingRequirements = false;
        _isResubmitting = true;
        // Reset files on new attempt
        _documentFront = null;
        _documentBack = null;
        _selfie = null;
      });
    }
  }

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
                  onPressed: _startResubmission,
                  isLoading: _isLoadingRequirements,
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
    final requiredDocs = _requirements?.requiredDocs ?? [];
    final showAll = requiredDocs.isEmpty;
    final showIdCard = showAll || requiredDocs.contains('ID_CARD');
    final showPassport = showAll || requiredDocs.contains('PASSPORT');
    final showDriverLicense =
        showAll || requiredDocs.contains('DRIVERS_LICENSE');
    final showSelfie = showAll || requiredDocs.contains('SELFIE');

    // Determine which internal flags to activate
    // ID_CARD, DRIVERS_LICENSE imply Front & Back usually. PASSPORT usually front.
    final bool askFront = showIdCard || showPassport || showDriverLicense;
    final bool askBack = showIdCard || showDriverLicense;
    final bool askSelfie = showSelfie;

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_requirements?.moderationComment != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Text(
                    _requirements!.moderationComment!,
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Please upload the required documents.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (askFront) ...[
                if (_documentFront == null)
                  _buildSingleUploadBox(
                    label: 'Document Front',
                    type: 'front',
                    header: 'Upload Front Side',
                    subText: 'Select JPG, PNG or take a photo',
                  )
                else
                  _buildCompactPreview(
                    label: 'Document Front',
                    path: _documentFront!.path,
                    file: _documentFront!,
                    onRemove: () => setState(() => _documentFront = null),
                  ),
                const SizedBox(height: 24),
              ],
              if (askBack) ...[
                if (_documentBack == null)
                  _buildSingleUploadBox(
                    label: 'Document Back',
                    type: 'back',
                    header: 'Upload Back Side',
                    subText: 'Select JPG, PNG or take a photo',
                  )
                else
                  _buildCompactPreview(
                    label: 'Document Back',
                    path: _documentBack!.path,
                    file: _documentBack!,
                    onRemove: () => setState(() => _documentBack = null),
                  ),
                const SizedBox(height: 24),
              ],
              if (askSelfie) ...[
                if (_selfie == null)
                  _buildSingleUploadBox(
                    label: 'Selfie',
                    type: 'selfie',
                    header: 'Take a Selfie',
                    subText: 'Look directly at the camera',
                    icon: Icons.camera_front,
                  )
                else
                  _buildCompactPreview(
                    label: 'Selfie',
                    path: _selfie!.path,
                    file: _selfie!,
                    onRemove: () => setState(() => _selfie = null),
                  ),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 24),
              AppButton(
                text: 'Submit Documents',
                isLoading: _isLoading,
                onPressed: _handleResubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleUploadBox({
    required String label,
    required String type,
    required String header,
    required String subText,
    IconData icon = Icons.upload_file,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greyText.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.primaryGold,
          ),
          const SizedBox(height: 16),
          Text(
            header,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.whiteText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subText,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.greyText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Maximum file size: 2MB',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _pickImage(type),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.darkBackground,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            icon: Icon(icon),
            label: Text(label.startsWith('Upload') || label.startsWith('Take')
                ? label
                : 'Upload $label'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPreview({
    required String label,
    required String path,
    required File file,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.successGreen,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.successGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  path.split('/').last,
                  style:
                      const TextStyle(color: AppColors.greyText, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Preview thumbnail
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
