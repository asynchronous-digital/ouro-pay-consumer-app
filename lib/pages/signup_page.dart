import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:ouro_pay_consumer_app/widgets/logo.dart';
import 'package:ouro_pay_consumer_app/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:pinput/pinput.dart';
import 'dart:io';
import 'package:ouro_pay_consumer_app/models/country.dart';

import 'package:flutter_image_compress/flutter_image_compress.dart';

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
  final int _totalSteps = 5;

  // Form controllers
  final _personalFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _otpController = TextEditingController();

  // Field-specific error messages from API
  String? _firstNameError;

  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _dobError;

  // KYC state
  // Removed static selected country; will be set dynamically
  String _selectedDocumentType = 'National ID';
  bool _documentFrontUploaded = false;
  bool _documentBackUploaded = false;
  bool _selfieCompleted = false;
  bool _termsAccepted = false;
  bool _isStepOneSubmitting = false;
  bool _isOtpSubmitting = false;

  // Document files (front and back)
  File? _documentFrontFile;
  String? _documentFrontPath;
  File? _documentBackFile;
  String? _documentBackPath;
  File? _selfieFile;
  String? _selfiePath;
  final ImagePicker _imagePicker = ImagePicker();

  // Password visibility toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Country data
  List<Country> _countries = [];
  bool _isLoadingCountries = false;
  Country? _selectedCountry;
  bool _hasSelectedCountry =
      false; // Track if user has manually selected a country

  // Country code for phone number
  String _countryCode = '+1'; // Default to US

  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
    _fetchCountries();

    // Add listeners to update button state when fields change
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    _dobController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
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
    _otpController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Dismiss keyboard when moving between steps
    FocusScope.of(context).unfocus();

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
                  _buildOtpVerificationStep(),
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
                              width:
                                  30, // Reduced width for connectors to fit 5 steps
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
        return 'Email Verification';
      case 2:
        return 'Document Verification';
      case 3:
        return 'Identity Verification';
      case 4:
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

            // Phone Number with Country Code
            FormField<String>(
              validator: (value) {
                if (_phoneController.text.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (_phoneError != null) {
                  return _phoneError;
                }
                return null;
              },
              builder: (FormFieldState<String> state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: state.hasError
                              ? AppColors.errorRed
                              : AppColors.greyText.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Country Dropdown from API
                          Expanded(
                            flex:
                                3, // Using 3 (approx 25-30%) because 2 (20%) is too small for "Country + Code"
                            child: _isLoadingCountries
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: DropdownButton<Country>(
                                      value: _selectedCountry,
                                      underline: const SizedBox(),
                                      dropdownColor: AppColors.cardBackground,
                                      isDense: true,
                                      isExpanded: true,
                                      menuMaxHeight: 400,
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.primaryGold,
                                        size: 20,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.whiteText,
                                        fontSize: 14,
                                      ),
                                      selectedItemBuilder:
                                          (BuildContext context) {
                                        return _countries
                                            .map((Country country) {
                                          return Center(
                                            child: Text(
                                              _hasSelectedCountry
                                                  ? country.phoneCode
                                                  : country.name,
                                              style: const TextStyle(
                                                color: AppColors.whiteText,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList();
                                      },
                                      items: _countries.map((Country country) {
                                        return DropdownMenuItem<Country>(
                                          value: country,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  country.name,
                                                  style: const TextStyle(
                                                    color: AppColors.whiteText,
                                                    fontSize: 15,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                country.phoneCode,
                                                style: const TextStyle(
                                                  color: AppColors.primaryGold,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (Country? newCountry) {
                                        if (newCountry != null) {
                                          setState(() {
                                            _selectedCountry = newCountry;
                                            _countryCode = newCountry.phoneCode;
                                            _hasSelectedCountry =
                                                true; // Mark that user has selected
                                          });
                                        }
                                      },
                                    ),
                                  ),
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: AppColors.greyText.withOpacity(0.3),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 7,
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style:
                                  const TextStyle(color: AppColors.whiteText),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Phone number',
                                hintStyle: TextStyle(color: AppColors.greyText),
                              ),
                              onChanged: (value) {
                                state.didChange(value);
                                if (_phoneError != null) {
                                  setState(() => _phoneError = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          state.errorText!,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
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
                onPressed:
                    (_isStepOneSubmitting || !_canProceedFromPersonalInfo())
                        ? null
                        : () {
                            _handleStepOneContinue();
                          },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.darkBackground,
                  disabledBackgroundColor: AppColors.greyText,
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
    if (_isStepOneSubmitting) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isStepOneSubmitting = true;
      // Clear previous errors
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _phoneError = null;
      _dobError = null;
      _passwordError = null;
    });

    try {
      // Format date of birth to ISO format (YYYY-MM-DD)
      final formattedDob = _formatDateOfBirth(_dobController.text);
      final phone = '$_countryCode${_phoneController.text.trim()}';

      // Call validation API
      final validationResponse = await AuthService().validateStep1(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: phone,
        dateOfBirth: formattedDob,
        password: _passwordController.text,
        countryId: _selectedCountry?.id.toString(),
      );

      if (!mounted) return;

      if (validationResponse.success) {
        // Validation successful, proceed to send OTP
        final email = _emailController.text.trim();
        final success = await AuthService().sendOtp(email);

        if (!mounted) return;

        setState(() {
          _isStepOneSubmitting = false;
        });

        if (success) {
          // Show success message at top and proceed to next step
          _showBottomSnackBar('OTP sent successfully. Please check your email.',
              AppColors.successGreen);
          _nextStep();
        } else {
          _showBottomSnackBar(
              'Failed to send OTP. Please try again.', AppColors.errorRed);
        }
      } else {
        // Validation failed, show errors
        setState(() {
          _isStepOneSubmitting = false;

          if (validationResponse.errors != null) {
            final errors = validationResponse.errors!;

            if (errors.containsKey('first_name')) {
              _firstNameError = errors['first_name']!.first;
            }
            if (errors.containsKey('last_name')) {
              _lastNameError = errors['last_name']!.first;
            }
            if (errors.containsKey('email')) {
              _emailError = errors['email']!.first;
            }
            if (errors.containsKey('phone')) {
              _phoneError = errors['phone']!.first;
            }
            if (errors.containsKey('date_of_birth')) {
              _dobError = errors['date_of_birth']!.first;
            }
            if (errors.containsKey('password')) {
              _passwordError = errors['password']!.first;
            }
            if (errors.containsKey('country_id')) {
              _showBottomSnackBar(
                  errors['country_id']!.first, AppColors.errorRed);
            }
          }
        });

        if (validationResponse.message != null) {
          _showBottomSnackBar(validationResponse.message!, AppColors.errorRed);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStepOneSubmitting = false;
      });
      _showBottomSnackBar('An error occurred: $e', AppColors.errorRed);
    }
  }

  Widget _buildOtpVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OuroPayIcon(size: 48),
          const SizedBox(height: 24),

          const Text(
            'Check your email',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.whiteText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We sent a verification code to ${_emailController.text}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.greyText,
            ),
          ),
          const SizedBox(height: 32),

          // OTP PIN Input
          Pinput(
            controller: _otpController,
            length: 6,
            defaultPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 20,
                color: AppColors.whiteText,
                fontWeight: FontWeight.w600,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.greyText.withOpacity(0.3),
                ),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 20,
                color: AppColors.whiteText,
                fontWeight: FontWeight.w600,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGold,
                  width: 2,
                ),
              ),
            ),
            submittedPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 20,
                color: AppColors.whiteText,
                fontWeight: FontWeight.w600,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.5),
                ),
              ),
            ),
            errorPinTheme: PinTheme(
              width: 56,
              height: 56,
              textStyle: const TextStyle(
                fontSize: 20,
                color: AppColors.whiteText,
                fontWeight: FontWeight.w600,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorRed,
                  width: 2,
                ),
              ),
            ),
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            onCompleted: (pin) {
              // Auto-submit when all 6 digits are entered
              if (pin.length == 6) {
                _handleOtpVerification();
              }
            },
          ),
          const SizedBox(height: 32),

          // Verify Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isOtpSubmitting ? null : _handleOtpVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isOtpSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.darkBackground,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Verify Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _isOtpSubmitting
                  ? null
                  : () async {
                      // Resend OTP logic
                      await _handleStepOneContinue();
                    },
              child: const Text(
                'Resend Code',
                style: TextStyle(color: AppColors.primaryGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOtpVerification() async {
    if (_isOtpSubmitting) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showBottomSnackBar('Please enter your email first', AppColors.errorRed);
      return;
    }

    if (otp.length != 6) {
      _showBottomSnackBar('Please enter all 6 digits', AppColors.errorRed);
      return;
    }

    setState(() {
      _isOtpSubmitting = true;
    });

    try {
      final email = _emailController.text.trim();
      final success = await AuthService().verifyOtp(email, otp);

      if (!mounted) return;

      setState(() {
        _isOtpSubmitting = false;
      });

      if (success) {
        _showBottomSnackBar(
            'OTP verified successfully!', AppColors.successGreen);
      } else {
        _showBottomSnackBar(
            'Verification failed, but proceeding for development',
            AppColors.warningOrange);
      }

      // Proceed to next step regardless of verification result (for development)
      _nextStep();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOtpSubmitting = false;
      });
      _showBottomSnackBar('Error occurred, but proceeding for development',
          AppColors.warningOrange);

      // Proceed to next step even on error (for development)
      _nextStep();
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
            'Upload your National ID to verify your identity.',
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
          _isLoadingCountries
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.greyText.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading countries...',
                        style: TextStyle(color: AppColors.greyText),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<Country>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.greyText.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.greyText.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGold,
                        width: 2,
                      ),
                    ),
                  ),
                  isExpanded: true,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(color: AppColors.whiteText),
                  items: _countries
                      .map((country) => DropdownMenuItem<Country>(
                            value: country,
                            child: Text(country.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                    });
                  },
                ),
          const SizedBox(height: 24),

          // Document Type Selection (Re-enabled all options)
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

          // Dynamic Upload Section
          _buildDynamicUploadSection(),

          const SizedBox(height: 32),

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_documentFrontUploaded &&
                      _documentBackUploaded &&
                      !_isLoadingCountries &&
                      _selectedCountry != null)
                  ? _nextStep
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.darkBackground,
                disabledBackgroundColor: AppColors.greyText,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoadingCountries
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
    );
  }

  Widget _buildDynamicUploadSection() {
    // Stage 1: Upload Front
    if (!_documentFrontUploaded) {
      return _buildSingleUploadBox(
        label: 'Front Side',
        isBackSide: false,
        header: 'Upload $_selectedDocumentType Front',
      );
    }
    // Stage 2: Upload Back
    else if (!_documentBackUploaded) {
      return Column(
        children: [
          _buildCompactPreview(
              'Front Side', _documentFrontPath!, _documentFrontFile!),
          const SizedBox(height: 24),
          _buildSingleUploadBox(
            label: 'Back Side',
            isBackSide: true,
            header: 'Now please select the back side',
          ),
        ],
      );
    }
    // Stage 3: Both Uploaded
    else {
      return Column(
        children: [
          _buildCompactPreview(
              'Front Side', _documentFrontPath!, _documentFrontFile!),
          const SizedBox(height: 16),
          _buildCompactPreview(
              'Back Side', _documentBackPath!, _documentBackFile!),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _documentFrontFile = null;
                _documentFrontPath = null;
                _documentFrontUploaded = false;
                _documentBackFile = null;
                _documentBackPath = null;
                _documentBackUploaded = false;
              });
            },
            icon: const Icon(Icons.refresh, color: AppColors.errorRed),
            label: const Text(
              'Reset and Upload Again',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSingleUploadBox({
    required String label,
    required bool isBackSide,
    required String header,
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
          const Icon(
            Icons.upload_file,
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
          const Text(
            'Select JPG, PNG or take a photo',
            style: TextStyle(
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
            onPressed: () => _startDocumentCapture(isBackSide: isBackSide),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.darkBackground,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.upload_file),
            label: Text('Upload $label'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPreview(String label, String path, File file) {
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
          // Preview snippet (optional)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
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
          if (_selfieFile != null)
            // Show preview when selfie is captured
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.successGreen,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.successGreen,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Selfie Captured',
                            style: TextStyle(
                              color: AppColors.whiteText,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Selfie Preview Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selfieFile!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Face verification completed ✓',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Retake button below preview
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Clear the previous selfie preview
                      setState(() {
                        _selfieCompleted = false;
                        _selfieFile = null;
                        _selfiePath = null;
                      });
                      // Then start new capture
                      _startSelfieCapture();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGold,
                      side: const BorderSide(color: AppColors.primaryGold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake Selfie'),
                  ),
                ),
              ],
            )
          else
            // Show capture button when no selfie
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.greyText.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_front,
                    size: 64,
                    color: AppColors.primaryGold,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ready to take your selfie?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Position your face in the frame',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 16),
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
              onPressed: _nextStep, // Always enabled for development
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
              'Country: ${_selectedCountry?.name ?? "Not selected"}',
              'Document Type: $_selectedDocumentType',
              'Document Status: ${_documentFrontUploaded && _documentBackUploaded ? "Uploaded ✓" : "Pending"}',
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

  Future<void> _startDocumentCapture({required bool isBackSide}) async {
    // Show options for document upload
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
                'Upload ${isBackSide ? "Back Side" : "Front Side"}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.whiteText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your $_selectedDocumentType (${isBackSide ? "Back" : "Front"})',
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
                  'Use your camera to capture document',
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera(isBackSide: isBackSide);
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
                  _pickImageFromGallery(isBackSide: isBackSide);
                },
              ),
              const SizedBox(height: 8),

              // Select PDF option
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
                  _pickPdfFile(isBackSide: isBackSide);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera({required bool isBackSide}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        // Compress image to ensure it's under 2MB
        final compressedFile = await _compressImage(File(image.path));

        if (compressedFile == null) {
          if (!mounted) return;
          _showBottomSnackBar('Failed to process image', AppColors.errorRed);
          return;
        }

        final fileSize = await compressedFile.length();

        // Check file size (max 2MB)
        if (fileSize > 2 * 1024 * 1024) {
          if (!mounted) return;
          _showBottomSnackBar(
              'File size must be less than 2MB', AppColors.errorRed);
          return;
        }

        setState(() {
          if (isBackSide) {
            _documentBackFile = compressedFile;
            _documentBackPath = compressedFile.path;
            _documentBackUploaded = true;
          } else {
            _documentFrontFile = compressedFile;
            _documentFrontPath = compressedFile.path;
            _documentFrontUploaded = true;
          }
        });

        if (!mounted) return;

        _showBottomSnackBar(
            'Document captured successfully!', AppColors.successGreen);
      }
    } catch (e) {
      if (!mounted) return;
      _showBottomSnackBar(
          'Error capturing image: ${e.toString()}', AppColors.errorRed);
    }
  }

  Future<void> _pickImageFromGallery({required bool isBackSide}) async {
    try {
      print('📸 Starting image picker from gallery...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      print(
          '📸 Image picker result: ${image?.path ?? "null - user cancelled"}');

      if (image != null) {
        print('📸 Image selected, starting compression...');
        // Compress image to ensure it's under 2MB
        final compressedFile = await _compressImage(File(image.path));

        if (compressedFile == null) {
          print('❌ Compression failed - compressedFile is null');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process image'),
              backgroundColor: AppColors.errorRed,
            ),
          );
          return;
        }

        final fileSize = await compressedFile.length();
        print('📸 Compressed file size: ${fileSize / 1024 / 1024} MB');

        // Check file size (max 2MB)
        if (fileSize > 2 * 1024 * 1024) {
          print('❌ File too large: ${fileSize / 1024 / 1024} MB');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 2MB'),
              backgroundColor: AppColors.errorRed,
            ),
          );
          return;
        }

        print('✅ Setting state with document file...');
        setState(() {
          if (isBackSide) {
            _documentBackFile = compressedFile;
            _documentBackPath = compressedFile.path;
            _documentBackUploaded = true;
          } else {
            _documentFrontFile = compressedFile;
            _documentFrontPath = compressedFile.path;
            _documentFrontUploaded = true;
          }
        });

        if (!mounted) return;

        print('✅ Document selected successfully!');
        _showBottomSnackBar(
            'Document selected successfully!', AppColors.successGreen);
      } else {
        print('ℹ️ No image selected (user cancelled)');
      }
    } catch (e) {
      print('❌ Error in _pickImageFromGallery: $e');
      if (!mounted) return;
      _showBottomSnackBar(
          'Error selecting image: ${e.toString()}', AppColors.errorRed);
    }
  }

  Future<void> _pickPdfFile({required bool isBackSide}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Check file size (max 2MB)
        if (fileSize > 2 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 2MB'),
              backgroundColor: AppColors.errorRed,
            ),
          );
          return;
        }

        setState(() {
          if (isBackSide) {
            _documentBackFile = file;
            _documentBackPath = result.files.single.path;
            _documentBackUploaded = true;
          } else {
            _documentFrontFile = file;
            _documentFrontPath = result.files.single.path;
            _documentFrontUploaded = true;
          }
        });

        if (!mounted) return;

        _showBottomSnackBar(
            'Document uploaded successfully!', AppColors.successGreen);
      }
    } catch (e) {
      if (!mounted) return;
      _showBottomSnackBar(
          'Error selecting PDF: ${e.toString()}', AppColors.errorRed);
    }
  }

  /// Compress image to ensure it's under 2MB
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, lastIndex);
      final outPath = '${splitted}_compressed.jpg';

      // Start with 85% quality
      int quality = 85;
      File? compressedFile;

      // Try compressing with decreasing quality until file is under 2MB
      while (quality >= 40) {
        final result = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          outPath,
          quality: quality,
          minWidth: 1920,
          minHeight: 1920,
        );

        if (result == null) break;

        compressedFile = File(result.path);
        final fileSize = await compressedFile.length();

        // If file is under 2MB, we're done
        if (fileSize <= 2 * 1024 * 1024) {
          return compressedFile;
        }

        // Reduce quality for next attempt
        quality -= 15;
      }

      // Return the most compressed version we got
      return compressedFile ?? file;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }

  Future<void> _startSelfieCapture() async {
    // 1. Show instructions dialog
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Selfie Verification',
          style: TextStyle(color: AppColors.whiteText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'To verify your identity, please take a clear selfie.',
              style: TextStyle(color: AppColors.whiteText),
            ),
            SizedBox(height: 16),
            Text(
              '• Remove glasses, hats, or masks',
              style: TextStyle(color: AppColors.greyText),
            ),
            Text(
              '• Ensure your face is fully visible',
              style: TextStyle(color: AppColors.greyText),
            ),
            Text(
              '• Look straight at the camera',
              style: TextStyle(color: AppColors.greyText),
            ),
            Text(
              '• Ensure good lighting',
              style: TextStyle(color: AppColors.greyText),
            ),
          ],
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
              'I\'m Ready',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    try {
      // 2. Capture image from front camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        return;
      }

      // IMPORTANT: Compress/fix image BEFORE face detection
      // This ensures the image is in the correct orientation and format for ML Kit
      final compressedSelfie = await _compressImage(File(image.path));

      if (compressedSelfie == null) {
        _showError('Failed to process selfie image');
        return;
      }

      // 3. Process image for face detection (using the compressed/fixed image)
      final inputImage = InputImage.fromFilePath(compressedSelfie.path);
      final options = FaceDetectorOptions(
        enableClassification: true, // For eyes open/smile
        enableLandmarks: true, // For detailed positioning if needed
        performanceMode: FaceDetectorMode.accurate,
      );
      final faceDetector = FaceDetector(options: options);
      final List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (!mounted) return;

      // 4. Validate face
      if (faces.isEmpty) {
        _showError(
            'No face detected. Please ensure your face is clearly visible.');
        return;
      }

      if (faces.length > 1) {
        _showError(
            'Multiple faces detected. Please ensure only you are in the frame.');
        return;
      }

      final Face face = faces.first;

      // Check head rotation (looking straight)
      // Euler X: Up/Down (should be close to 0)
      // Euler Y: Left/Right (should be close to 0)
      final double? rotX = face.headEulerAngleX;
      final double? rotY = face.headEulerAngleY;

      if (rotX != null && (rotX < -15 || rotX > 15)) {
        _showError('Please look straight at the camera (head tilted up/down).');
        return;
      }

      if (rotY != null && (rotY < -15 || rotY > 15)) {
        _showError(
            'Please look straight at the camera (head turned left/right).');
        return;
      }

      // Check eyes open probability (detect blinking or sunglasses)
      final double? leftEyeOpen = face.leftEyeOpenProbability;
      final double? rightEyeOpen = face.rightEyeOpenProbability;

      if (leftEyeOpen != null && rightEyeOpen != null) {
        if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
          _showError('Please keep your eyes open and don\'t blink.');
          return;
        }
      }

      setState(() {
        _selfieCompleted = true;
        _selfieFile = compressedSelfie;
        _selfiePath = compressedSelfie.path;
      });

      // Show success snackbar (preview is already visible on the page)
      _showBottomSnackBar(
          'Selfie verified successfully!', AppColors.successGreen);
    } catch (e) {
      print('❌ Error in selfie capture: $e');
      if (!mounted) return;
      _showError('Error processing selfie: ${e.toString()}');
    }
  }

  void _showBottomSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    _showBottomSnackBar(message, AppColors.errorRed);
  }

  Future<void> _fetchCountries() async {
    setState(() {
      _isLoadingCountries = true;
    });

    try {
      final countries = await AuthService().getCountries();

      if (!mounted) return;

      setState(() {
        _countries = countries;
        _isLoadingCountries = false;

        // Set default country if available
        if (_countries.isNotEmpty && _selectedCountry == null) {
          _selectedCountry = _countries.first;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCountries = false;
      });

      print('Error fetching countries: $e');

      // Show error message to user
      _showBottomSnackBar('Failed to load countries: $e', AppColors.errorRed);
    }
  }

  bool _canProceedFromPersonalInfo() {
    // Check if all required fields are filled
    final isValid = _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _dobController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    print('👉 _canProceedFromPersonalInfo: $isValid');
    return isValid;
  }

  bool _canSubmit() {
    return _documentFrontUploaded &&
        _documentBackUploaded &&
        _selfieCompleted &&
        _termsAccepted;
  }

  String _getDocumentTypeForApi() {
    // Return national_id specifically for now
    return 'national_id';
  }

  Future<void> _submitRegistration() async {
    // Validate all required fields
    if (_selectedCountry == null) {
      _showError('Please select a country');
      return;
    }

    if (_documentFrontFile == null || _documentFrontPath == null) {
      _showError('Please upload front side of your document');
      return;
    }

    if (_documentBackFile == null || _documentBackPath == null) {
      _showError('Please upload back side of your document');
      return;
    }

    if (!_selfieCompleted || _selfiePath == null) {
      _showError('Please complete selfie verification');
      return;
    }

    if (!_termsAccepted) {
      _showError('Please accept the Terms and Conditions');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: AppColors.cardBackground,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryGold),
                SizedBox(height: 16),
                Text(
                  'Creating your account...',
                  style: TextStyle(color: AppColors.whiteText),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Format date of birth to ISO format (YYYY-MM-DD)
      final formattedDob = _formatDateOfBirth(_dobController.text);

      // Call registration API with documents
      final response = await AuthService().registerWithDocuments(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        dateOfBirth: formattedDob,
        phone: '$_countryCode${_phoneController.text.trim()}',
        otp: '000000', // Fixed OTP as per requirement
        countryId: _selectedCountry!.id,
        documentType: _getDocumentTypeForApi(),
        documentFrontPath: _documentFrontPath!,
        documentBackPath: _documentBackPath!,
        selfiePath: _selfiePath!,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.success) {
        // Reset form fields
        _resetForm();

        // Show success toast message
        // Toast removed as per request, relying on the one in LoginPage

        // Navigate to login page, replacing the signup page
        Navigator.of(context).pushReplacementNamed(
          '/login',
          arguments: {'registrationSuccess': true},
        );
      } else {
        // Handle validation errors
        if (response.errors != null && response.errors!.isNotEmpty) {
          // Build error message from all field errors
          final errorMessages = <String>[];
          response.errors!.forEach((field, messages) {
            errorMessages.addAll(messages);
          });

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColors.errorRed, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Validation Error',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errorMessages
                      .map((error) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style:
                                        TextStyle(color: AppColors.errorRed)),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: const TextStyle(
                                        color: AppColors.whiteText),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: AppColors.primaryGold),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show general error message in a Dialog
          _showErrorDialog('Error',
              response.message ?? 'Registration failed. Please try again.');
        }
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      _showErrorDialog('Error', 'An error occurred: ${e.toString()}');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.errorRed, size: 32),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.whiteText),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Do not reset form on general error so user can retry
            },
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _dobController.clear();
    _otpController.clear();

    setState(() {
      _documentFrontFile = null;
      _documentFrontPath = null;
      _documentFrontUploaded = false;
      _documentBackFile = null;
      _documentBackPath = null;
      _documentBackUploaded = false;
      _selfieFile = null;
      _selfiePath = null;
      _selfieCompleted = false;
      _termsAccepted = false;
      _currentStep = 0;
      _selectedCountry = null;
      _countryCode = '+1';
    });

    // Reset page controller to first page
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
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
