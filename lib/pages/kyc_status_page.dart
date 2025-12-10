import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    if (widget.kycData.status == 'rejected') {
      _fetchRequirements();
    }
  }

  Future<void> _fetchRequirements() async {
    setState(() {
      _isLoadingRequirements = true;
    });

    final requirements = await KycService().getKycRequirements();

    if (mounted) {
      setState(() {
        _requirements = requirements;
        _isLoadingRequirements = false;
      });
    }
  }

  Future<void> _startResubmission() async {
    if (_requirements == null) {
      await _fetchRequirements();
    }

    // If still blocked after fetch (should be handled by UI, but double check)
    if (_requirements != null && !_requirements!.canResubmit) {
      return;
    }

    if (mounted) {
      setState(() {
        _isResubmitting = true;
        // Reset files on new attempt
        _documentFront = null;
        _documentBack = null;
        _selfie = null;
      });
    }
  }

  Future<void> _startSelection(String type) async {
    // Show options for document upload
    // For selfie, we might want to suggest camera primarily, but let's give options if user wants.
    // Signup usually forces camera for selfie for liveness, but here we will provide options as requested.

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload ${type == 'front' ? "Front Side" : type == 'back' ? "Back Side" : "Selfie"}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select upload method',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 24),

              // Take Photo option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryGold,
                  ),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(
                    color: AppColors.whiteText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Use your camera to capture',
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera(type);
                },
              ),
              const SizedBox(height: 8),

              // Choose from Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryGold,
                  ),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: AppColors.whiteText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Select JPG or PNG image',
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery(type);
                },
              ),

              // Select PDF option (Only for documents, not selfie)
              if (type != 'selfie') ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.primaryGold,
                    ),
                  ),
                  title: const Text(
                    'Select PDF File',
                    style: TextStyle(
                      color: AppColors.whiteText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Choose PDF document',
                    style: TextStyle(color: AppColors.greyText, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPdfFile(type);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera(String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final compressedFile = await _compressImage(File(image.path));
        if (compressedFile == null) {
          _showBottomSnackBar('Failed to process image', AppColors.errorRed);
          return;
        }

        final fileSize = await compressedFile.length();
        if (fileSize > 2 * 1024 * 1024) {
          _showBottomSnackBar(
              'File size must be less than 2MB', AppColors.errorRed);
          return;
        }

        _setFile(type, compressedFile);
      }
    } catch (e) {
      _showBottomSnackBar('Error capturing image: $e', AppColors.errorRed);
    }
  }

  Future<void> _pickImageFromGallery(String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        final compressedFile = await _compressImage(File(image.path));
        if (compressedFile == null) {
          _showBottomSnackBar('Failed to process image', AppColors.errorRed);
          return;
        }

        final fileSize = await compressedFile.length();
        if (fileSize > 2 * 1024 * 1024) {
          _showBottomSnackBar(
              'File size must be less than 2MB', AppColors.errorRed);
          return;
        }

        _setFile(type, compressedFile);
      }
    } catch (e) {
      _showBottomSnackBar('Error selecting image: $e', AppColors.errorRed);
    }
  }

  Future<void> _pickPdfFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize > 2 * 1024 * 1024) {
          _showBottomSnackBar(
              'File size must be less than 2MB', AppColors.errorRed);
          return;
        }

        _setFile(type, file);
      }
    } catch (e) {
      _showBottomSnackBar('Error selecting PDF: $e', AppColors.errorRed);
    }
  }

  void _setFile(String type, File file) {
    setState(() {
      if (type == 'front')
        _documentFront = file;
      else if (type == 'back')
        _documentBack = file;
      else if (type == 'selfie') _selfie = file;
    });
  }

  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      if (lastIndex == -1)
        return file; // If not jpg/jpeg, return original (or handle png)

      final splitted = filePath.substring(0, lastIndex);
      final outPath = '${splitted}_compressed.jpg';

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 85,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      return file;
    }
  }

  void _showBottomSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleResubmit() async {
    if (_requirements != null && !_requirements!.canResubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _requirements!.resubmissionReason ?? 'Resubmission not allowed'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

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

        // Navigate to dashboard instead of splash
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/dashboard', (route) => false);
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
    setState(() => _isLoggingOut = true);
    await AuthService().logout();
    if (mounted) {
      setState(() => _isLoggingOut = false);
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
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                ),
              ),
            )
          else
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
              if (_isLoadingRequirements)
                const AppButton(
                  text: 'Loading...',
                  isLoading: true,
                )
              else if (_requirements != null) ...[
                AppButton(
                  text: 'Resubmit KYC Information',
                  onPressed: _requirements!.canResubmit
                      ? _startResubmission
                      : null, // Disabled if false
                ),
                if (!_requirements!.canResubmit &&
                    _requirements!.resubmissionReason != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _requirements!.resubmissionReason!,
                    style: const TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ] else if (widget.kycData.canResubmit)
                AppButton(
                  text: 'Resubmit KYC Information',
                  onPressed: _startResubmission,
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
            onPressed: () => _startSelection(type),
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
