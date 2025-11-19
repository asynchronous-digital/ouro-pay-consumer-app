import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/widgets/logo.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final _personalFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();

  // Field-specific error messages from API
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _dobError;

  // KYC state
  String _selectedCountry = 'United States';
  String _selectedDocumentType = 'Passport';
  bool _documentsUploaded = false;
  bool _selfieCompleted = false;
  bool _termsAccepted = false;
  bool _isStepOneSubmitting = false;

  // Password visibility toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.primaryGold),
                onPressed: _previousStep,
              )
            : IconButton(
                icon:
                    const Icon(Icons.arrow_back, color: AppColors.primaryGold),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Main content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalInfoStep(),
                  _buildDocumentVerificationStep(),
                  _buildSelfieVerificationStep(),
                  _buildReviewAndSubmitStep(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Add this
                    children: List.generate(_totalSteps, (index) {
                      bool isActive = index <= _currentStep;
                      bool isCurrent = index == _currentStep;

                      return Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? AppColors.primaryGold
                                  : AppColors.greyText.withOpacity(0.3),
                              border: isCurrent
                                  ? Border.all(
                                      color: AppColors.primaryGold, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: isActive
                                  ? Icon(
                                      index < _currentStep
                                          ? Icons.check
                                          : Icons.circle,
                                      color: AppColors.darkBackground,
                                      size: 16,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: AppColors.greyText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                          if (index < _totalSteps - 1)
                            Container(
                              width: 40, // Fixed width for connectors
                              height: 2,
                              color: index < _currentStep
                                  ? AppColors.primaryGold
                                  : AppColors.greyText.withOpacity(0.3),
                            ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getStepTitle(_currentStep),
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Document Verification';
      case 2:
        return 'Identity Verification';
      case 3:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _personalFormKey,
        autovalidateMode: AutovalidateMode.always,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OuroPayIcon(size: 48),
            const SizedBox(height: 24),

            const Text(
              'Let\'s get started',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.whiteText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your OURO PAY account to start trading gold securely.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.greyText,
              ),
            ),
            const SizedBox(height: 32),

            // First Name
            _buildTextField(
              controller: _firstNameController,
              label: 'First Name',
              icon: Icons.person_outline,
              errorText: _firstNameError,
              onChanged: () {
                if (_firstNameError != null) {
                  setState(() {
                    _firstNameError = null;
                  });
                }
              },
              validator: (value) {
                if (_firstNameError != null) {
                  return _firstNameError;
                }
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Last Name
            _buildTextField(
              controller: _lastNameController,
              label: 'Last Name',
              icon: Icons.person_outline,
              errorText: _lastNameError,
              onChanged: () {
                if (_lastNameError != null) {
                  setState(() {
                    _lastNameError = null;
                  });
                }
              },
              validator: (value) {
                if (_lastNameError != null) {
                  return _lastNameError;
                }
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              onChanged: () {
                if (_emailError != null) {
                  setState(() {
                    _emailError = null;
                  });
                }
              },
              validator: (value) {
                if (_emailError != null) {
                  return _emailError;
                }
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              errorText: _phoneError,
              onChanged: () {
                if (_phoneError != null) {
                  setState(() {
                    _phoneError = null;
                  });
                }
              },
              validator: (value) {
                if (_phoneError != null) {
                  return _phoneError;
                }
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth
            _buildTextField(
              controller: _dobController,
              label: 'Date of Birth',
              icon: Icons.calendar_today_outlined,
              readOnly: true,
              errorText: _dobError,
              onTap: () {
                if (_dobError != null) {
                  setState(() {
                    _dobError = null;
                  });
                }
                _selectDateOfBirth();
              },
              validator: (value) {
                if (_dobError != null) {
                  return _dobError;
                }
                if (value == null || value.isEmpty) {
                  return 'Please select your date of birth';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              errorText: _passwordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.greyText,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              onChanged: () {
                if (_passwordError != null) {
                  setState(() {
                    _passwordError = null;
                  });
                }
                // Re-validate confirm password field when password changes
                if (_confirmPasswordController.text.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _personalFormKey.currentState?.validate();
                    }
                  });
                }
              },
              validator: (value) {
                if (_passwordError != null) {
                  return _passwordError;
                }
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: AppColors.greyText,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              onChanged: () {
                // Re-validate when confirm password changes
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _personalFormKey.currentState?.validate();
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                // Get the current password value directly from controller
                final password = _passwordController.text;
                final confirmPassword = value;

                // Debug: Print both values to help identify issues
                print('🔍 Password comparison:');
                print('  Password: "${password}" (length: ${password.length})');
                print(
                    '  Confirm: "${confirmPassword}" (length: ${confirmPassword.length})');
                print('  Match: ${password == confirmPassword}');

                // Direct comparison first
                if (confirmPassword == password) {
                  return null;
                }

                // If direct comparison fails, try trimming
                if (confirmPassword.trim() == password.trim()) {
                  return null;
                }

                // If still no match, return error
                return 'Passwords do not match';
              },
            ),
            const SizedBox(height: 32),

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isStepOneSubmitting
                    ? null
                    : () {
                        if (_personalFormKey.currentState!.validate()) {
                          _handleStepOneContinue();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isStepOneSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.darkBackground,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStepOneContinue() async {
    if (_isStepOneSubmitting) return;

    setState(() {
      _isStepOneSubmitting = true;
    });

    try {
      final authService = AuthService();
      final dateOfBirthISO = _formatDateOfBirth(_dobController.text);

      final response = await authService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: dateOfBirthISO,
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() {
        _isStepOneSubmitting = false;
      });

      if (response.success) {
        if (response.token != null) {
          await authService.saveToken(response.token!);
        }
        if (response.user != null) {
          await authService.saveUserData(response.user!);
        } else if (response.data != null &&
            response.data!['user'] != null &&
            response.data!['user'] is Map<String, dynamic>) {
          await authService
              .saveUserData(response.data!['user'] as Map<String, dynamic>);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ??
                'Account created. Continue with verification steps.'),
            backgroundColor: AppColors.primaryGold,
          ),
        );

        _nextStep();
      } else {
        // Handle field-specific validation errors
        print(
            '🔴 Registration failed. Response fieldErrors: ${response.fieldErrors}');
        if (response.fieldErrors != null && response.fieldErrors!.isNotEmpty) {
          // Map API field errors to our field error variables
          // Handle various possible field name formats
          Map<String, String> fieldErrorMap = {};
          response.fieldErrors!.forEach((field, error) {
            print('  📍 Mapping field error: "$field" -> "$error"');
            switch (field.toLowerCase()) {
              case 'firstname':
              case 'first_name':
                fieldErrorMap['firstName'] = error;
                break;
              case 'lastname':
              case 'last_name':
                fieldErrorMap['lastName'] = error;
                break;
              case 'email':
                fieldErrorMap['email'] = error;
                break;
              case 'phone':
              case 'phonenumber':
              case 'phone_number':
                fieldErrorMap['phone'] = error;
                break;
              case 'password':
                fieldErrorMap['password'] = error;
                break;
              case 'dateofbirth':
              case 'date_of_birth':
              case 'dob':
                fieldErrorMap['dob'] = error;
                break;
            }
          });

          print('✅ Mapped field errors: $fieldErrorMap');

          // Set all error state variables in one setState call
          setState(() {
            _firstNameError = fieldErrorMap['firstName'];
            _lastNameError = fieldErrorMap['lastName'];
            _emailError = fieldErrorMap['email'];
            _phoneError = fieldErrorMap['phone'];
            _passwordError = fieldErrorMap['password'];
            _dobError = fieldErrorMap['dob'];
          });

          print(
              '✅ Set state errors - firstName: $_firstNameError, email: $_emailError, phone: $_phoneError');

          // Trigger form validation to show the errors
          // Use a small delay to ensure state is updated before validation
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              // Force validation on all fields to display the errors
              _personalFormKey.currentState?.validate();
            }
          });

          // Show snackbar message along with field-specific errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ??
                  'Validation failed. Please check the fields below.'),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // Show generic error message if no field-specific errors were provided
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ??
                  'Registration failed. Please check your information and try again.'),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isStepOneSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Widget _buildDocumentVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Verification',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a government-issued ID to verify your identity. This helps us keep your account secure.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyText,
            ),
          ),
          const SizedBox(height: 32),

          // Country Selection
          const Text(
            'Country of Issue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyText.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                isExpanded: true,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: AppColors.whiteText),
                items: const [
                  DropdownMenuItem(
                      value: 'United States', child: Text('United States')),
                  DropdownMenuItem(value: 'Canada', child: Text('Canada')),
                  DropdownMenuItem(
                      value: 'United Kingdom', child: Text('United Kingdom')),
                  DropdownMenuItem(value: 'Germany', child: Text('Germany')),
                  DropdownMenuItem(value: 'France', child: Text('France')),
                  DropdownMenuItem(value: 'Suriname', child: Text('Suriname')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Document Type Selection
          const Text(
            'Document Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 12),

          _buildDocumentTypeCard('Passport', Icons.assignment_outlined,
              'Recommended - Accepted worldwide'),
          const SizedBox(height: 12),
          _buildDocumentTypeCard('Driver\'s License',
              Icons.credit_card_outlined, 'Government-issued photo ID'),
          const SizedBox(height: 12),
          _buildDocumentTypeCard('National ID', Icons.badge_outlined,
              'Government-issued identification'),

          const SizedBox(height: 32),

          // Document Upload Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _documentsUploaded
                    ? AppColors.successGreen
                    : AppColors.greyText.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _documentsUploaded ? Icons.check_circle : Icons.upload_file,
                  size: 48,
                  color: _documentsUploaded
                      ? AppColors.successGreen
                      : AppColors.primaryGold,
                ),
                const SizedBox(height: 16),
                Text(
                  _documentsUploaded
                      ? 'Documents uploaded successfully!'
                      : 'Upload $_selectedDocumentType',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _documentsUploaded
                        ? AppColors.successGreen
                        : AppColors.whiteText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _documentsUploaded
                      ? 'Front and back sides captured'
                      : 'We\'ll guide you through taking photos of both sides',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.greyText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (!_documentsUploaded)
                  ElevatedButton.icon(
                    onPressed: _startDocumentCapture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Capture'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _documentsUploaded ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selfie Verification',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a selfie to verify your identity. This ensures that you are the person in the document.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyText,
            ),
          ),
          const SizedBox(height: 32),

          // Selfie Instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Follow these steps for best results:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteText,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                    Icons.face, 'Look directly at the camera'),
                _buildInstructionItem(
                    Icons.wb_sunny_outlined, 'Ensure good lighting'),
                _buildInstructionItem(
                    Icons.remove_circle_outline, 'Remove glasses and hat'),
                _buildInstructionItem(
                    Icons.smartphone, 'Hold phone at eye level'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Selfie Capture Area
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selfieCompleted
                    ? AppColors.successGreen
                    : AppColors.greyText.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _selfieCompleted ? Icons.check_circle : Icons.camera_front,
                  size: 64,
                  color: _selfieCompleted
                      ? AppColors.successGreen
                      : AppColors.primaryGold,
                ),
                const SizedBox(height: 16),
                Text(
                  _selfieCompleted
                      ? 'Selfie captured successfully!'
                      : 'Ready to take your selfie?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _selfieCompleted
                        ? AppColors.successGreen
                        : AppColors.whiteText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selfieCompleted
                      ? 'Face verification completed'
                      : 'Position your face in the frame',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 16),
                if (!_selfieCompleted)
                  ElevatedButton.icon(
                    onPressed: _startSelfieCapture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Selfie'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selfieCompleted ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewAndSubmitStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please review your information and agree to our terms to complete your registration.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyText,
            ),
          ),
          const SizedBox(height: 32),

          // Personal Information Summary
          _buildSummarySection(
            'Personal Information',
            [
              'Name: ${_firstNameController.text} ${_lastNameController.text}',
              'Email: ${_emailController.text}',
              'Phone: ${_phoneController.text}',
              'Date of Birth: ${_dobController.text}',
            ],
          ),

          const SizedBox(height: 20),

          // KYC Verification Summary
          _buildSummarySection(
            'Identity Verification',
            [
              'Country: $_selectedCountry',
              'Document Type: $_selectedDocumentType',
              'Document Status: ${_documentsUploaded ? "Uploaded ✓" : "Pending"}',
              'Selfie Status: ${_selfieCompleted ? "Completed ✓" : "Pending"}',
            ],
          ),

          const SizedBox(height: 32),

          // Terms and Conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyText.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryGold,
                  title: RichText(
                    text: const TextSpan(
                      style:
                          TextStyle(color: AppColors.whiteText, fontSize: 14),
                      children: [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppColors.primaryGold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submitRegistration : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Your account will be reviewed and activated within 1-2 business days.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.greyText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    String? errorText,
    VoidCallback? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      validator: validator,
      style: const TextStyle(color: AppColors.whiteText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.greyText),
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.cardBackground,
        errorStyle: const TextStyle(color: AppColors.errorRed, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
      ),
    );
  }

  Widget _buildDocumentTypeCard(String title, IconData icon, String subtitle) {
    bool isSelected = _selectedDocumentType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDocumentType = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGold
                : AppColors.greyText.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGold : AppColors.greyText,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryGold
                          : AppColors.whiteText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryGold,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.greyText.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.whiteText,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGold,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  void _startDocumentCapture() {
    // Simulate document capture process
    // In real app, this would integrate with Sumsub/Veriff SDK
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Document Capture',
          style: TextStyle(color: AppColors.whiteText),
        ),
        content: const Text(
          'In a real implementation, this would launch the Sumsub or Veriff SDK for document capture.',
          style: TextStyle(color: AppColors.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _documentsUploaded = true;
              });
            },
            child: const Text(
              'Simulate Success',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _startSelfieCapture() {
    // Simulate selfie capture process
    // In real app, this would integrate with Sumsub/Veriff SDK
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Selfie Capture',
          style: TextStyle(color: AppColors.whiteText),
        ),
        content: const Text(
          'In a real implementation, this would launch the Sumsub or Veriff SDK for selfie capture and liveness detection.',
          style: TextStyle(color: AppColors.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selfieCompleted = true;
              });
            },
            child: const Text(
              'Simulate Success',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return _documentsUploaded && _selfieCompleted && _termsAccepted;
  }

  Future<void> _submitRegistration() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Additional Steps Pending',
          style: TextStyle(color: AppColors.primaryGold),
        ),
        content: const Text(
          'KYC and verification endpoints will be implemented in upcoming steps.',
          style: TextStyle(color: AppColors.whiteText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateOfBirth(String value) {
    try {
      final parts = value.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final dob = DateTime(year, month, day);
        return dob.toIso8601String().split('T').first;
      }
      return value;
    } catch (_) {
      return value;
    }
  }
}
