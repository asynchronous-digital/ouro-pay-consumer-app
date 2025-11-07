# Ouro Pay Consumer App

A Flutter application with development and production environment support using flavors.

## 🏗️ Project Structure

This project is configured with two main environments:
- **Development**: For testing and development with dev APIs and debug features
- **Production**: For live app store releases with production APIs

## 🚀 Environment Configuration

### Flavors Setup

The app uses Flutter flavors to manage different environments:

#### Development Environment
- **App Name**: "Ouro Pay Dev"
- **Bundle ID**: `com.ouropay.consumer.dev`  
- **API URL**: `https://api-dev.ouropay.com`
- **Debug Mode**: Enabled
- **Visual Indicator**: Orange theme with "DEV" badge

#### Production Environment  
- **App Name**: "Ouro Pay"
- **Bundle ID**: `com.ouropay.consumer`
- **API URL**: `https://api.ouropay.com`  
- **Debug Mode**: Disabled
- **Visual Indicator**: Blue theme with "PROD" badge

## 🛠️ Getting Started

### Prerequisites
- FVM (Flutter Version Manager) - **Recommended**
- Or Flutter SDK (3.35.7+ required)
- Dart SDK  
- Android Studio / Xcode (for device testing)

### FVM Setup (Recommended)

This project uses **FVM (Flutter Version Manager)** to ensure consistent Flutter versions across all developers.

#### 1. Install FVM

**macOS (using Homebrew)**
```bash
brew tap leoafarias/fvm
brew install fvm
```

**Other platforms**
```bash
dart pub global activate fvm
```

#### 2. Install Project Flutter Version
```bash
# This will read the .fvmrc file and install Flutter 3.35.7
fvm install

# Use the project's Flutter version
fvm use
```

#### 3. Verify FVM Setup
```bash
# Check FVM status
fvm list

# Check Flutter version (should show 3.35.7)
fvm flutter --version
```

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ouro_pay_consumer_app
   ```

2. **Setup Flutter version with FVM** (Recommended)
   ```bash
   # Install the project's Flutter version (reads from .fvmrc)
   fvm install
   
   # Use the project's Flutter version
   fvm use
   ```

3. **Set up environment configuration**
   ```bash
   # Copy example to create your environment files
   cp .env.example .env.development
   cp .env.example .env.production
   
   # Update each file with your actual configuration values
   # Edit .env.development and .env.production with your API keys, URLs, etc.
   ```

4. **Install dependencies**
   ```bash
   # Using FVM (recommended)
   fvm flutter pub get
   
   # Or using system Flutter
   flutter pub get
   
   # Or using Make
   make deps
   ```

5. **Verify Flutter installation**
   ```bash
   # Using FVM (recommended)
   fvm flutter doctor
   
   # Or using system Flutter
   flutter doctor
   
   # Or using Make  
   make doctor
   ```

## 🏃‍♂️ Running the App

### Using Make Commands (Recommended)

```bash
# Run development flavor
make dev

# Run production flavor  
make prod

# Run on specific platform
make dev-ios
make prod-ios
```

### Using FVM Commands (Recommended)

```bash
# Development flavor
fvm flutter run --flavor development --target lib/main_dev.dart

# Production flavor
fvm flutter run --flavor production --target lib/main_prod.dart

# Run on specific device
fvm flutter run --flavor development --target lib/main_dev.dart -d <device-id>

# Run with hot reload enabled
fvm flutter run --flavor development --target lib/main_dev.dart --hot
```

### Using Flutter Commands (Alternative)

```bash
# Development flavor
flutter run --flavor development --target lib/main_dev.dart

# Production flavor
flutter run --flavor production --target lib/main_prod.dart
```

### Using VS Code

Use the configured launch configurations in `.vscode/launch.json`:
- **Development**: Debug development flavor
- **Production**: Debug production flavor  
- **Development Release**: Release build of development flavor
- **Production Release**: Release build of production flavor

## 🔨 Building for Release

### Android

```bash
# Using Make (recommended)
make build-dev-android    # Development APK
make build-prod-android   # Production APK

# Using FVM (recommended for manual builds)
fvm flutter build apk --flavor development --target lib/main_dev.dart
fvm flutter build apk --flavor production --target lib/main_prod.dart

# Using system Flutter (alternative)
flutter build apk --flavor development --target lib/main_dev.dart
flutter build apk --flavor production --target lib/main_prod.dart
```

### iOS

```bash
# Using Make (recommended)
make build-dev-ios     # Development IPA
make build-prod-ios    # Production IPA

# Using FVM (recommended for manual builds)
fvm flutter build ios --flavor development --target lib/main_dev.dart --no-codesign
fvm flutter build ios --flavor production --target lib/main_prod.dart --no-codesign

# Using system Flutter (alternative)
flutter build ios --flavor development --target lib/main_dev.dart --no-codesign
flutter build ios --flavor production --target lib/main_prod.dart --no-codesign
```

## 📁 Key Files

### Core Application Files
- `lib/config/app_config.dart` - Environment configuration
- `lib/main_dev.dart` - Development entry point
- `lib/main_prod.dart` - Production entry point  
- `lib/app.dart` - Main app widget

### Platform Configuration
- `android/app/build.gradle` - Android flavor configuration
- `ios/Flutter/Development.xcconfig` - iOS development config
- `ios/Flutter/Production.xcconfig` - iOS production config

### Environment Configuration Files
- `.env.example` - Environment template with both dev and prod configurations
- `.env.development` - Development configuration (not tracked in git)
- `.env.production` - Production configuration (not tracked in git)

### Development Tools
- `.vscode/launch.json` - VS Code debug configurations
- `Makefile` - Development commands
- `.fvmrc` - FVM Flutter version configuration

## 🎯 FVM Usage Guide

### Why Use FVM?
- **Version Consistency**: Ensures all team members use the same Flutter version (3.35.7)
- **Project Isolation**: Different projects can use different Flutter versions
- **Easy Switching**: Switch between Flutter versions instantly
- **CI/CD Compatible**: Automated builds use exact same version as local development

### FVM Commands Reference

```bash
# Check current project's Flutter version
fvm flutter --version

# List all installed Flutter versions
fvm list

# Install a specific Flutter version
fvm install 3.35.7

# Use a specific version for current project
fvm use 3.35.7

# Run any Flutter command with FVM
fvm flutter <command>

# Examples:
fvm flutter pub get
fvm flutter clean
fvm flutter build apk
fvm flutter test
```

### FVM Configuration Files
- `.fvmrc` - Specifies Flutter version (3.35.7) for this project
- This file is committed to git to ensure team consistency

### Switching Between FVM and System Flutter
```bash
# Check which Flutter you're using
which flutter

# Use FVM Flutter (project-specific)
fvm flutter --version

# Use system Flutter (global)
flutter --version
```

## 🔧 Available Make Commands

Run `make help` to see all available commands. **Note**: All Make commands use FVM automatically.

- `make deps` - Get Flutter dependencies (uses `fvm flutter pub get`)
- `make clean` - Clean build files (uses `fvm flutter clean`)
- `make doctor` - Run Flutter doctor (uses `fvm flutter doctor`)
- `make dev` - Run development flavor (uses `fvm flutter run`)
- `make prod` - Run production flavor (uses `fvm flutter run`)
- `make dev-ios` - Run development flavor on iOS
- `make prod-ios` - Run production flavor on iOS
- `make build-dev-android` - Build development APK
- `make build-prod-android` - Build production APK

## 🌍 Environment Variables

The application uses environment files to manage configuration across different environments:

### Environment File Setup
1. Copy the example file to create your environment configurations:
   ```bash
   cp .env.example .env.development  
   cp .env.example .env.production
   ```

2. Update each file with your actual values:
   - **API Configuration**: Base URLs, timeouts, versions
   - **App Settings**: Names, bundle IDs, feature flags
   - **Third-party Services**: Sentry DSN, Firebase config, Analytics keys
   - **Security Settings**: SSL pinning, certificate transparency

### Important Notes
- Environment files (`.env.development`, `.env.production`) are excluded from git for security
- The example file (`.env.example`) is tracked and serves as a template for both environments
- Never commit actual API keys or sensitive data to version control

## 📱 Features by Environment

### Development Environment Features
- Debug banners and logs enabled
- Extended connection timeouts
- Development API endpoints
- Additional retry attempts
- Orange color scheme for easy identification
- Mock data support for offline development

### Production Environment Features  
- Optimized performance settings
- Production API endpoints
- Reduced connection timeouts
- Minimal retry attempts
- Professional blue color scheme
- Enhanced security features (SSL pinning, crash reporting)

## 🔍 Troubleshooting

### FVM Issues

**FVM not found**
```bash
# Install FVM first
brew install fvm  # macOS
# or
dart pub global activate fvm
```

**Wrong Flutter version**
```bash
# Install and use the correct version
fvm install 3.35.7
fvm use 3.35.7
```

**FVM commands not working**
```bash
# Make sure you're in the project directory
cd ouro_pay_consumer_app

# Check if .fvmrc exists
ls -la .fvmrc

# Verify FVM is configured
fvm flutter --version
```

### Build Issues

**Gradle version conflicts**
```bash
# Clean and rebuild
fvm flutter clean
fvm flutter pub get
```

**iOS build issues**
```bash
# Clean iOS build cache
cd ios
rm -rf Pods/
rm Podfile.lock
cd ..
fvm flutter clean
fvm flutter pub get
cd ios && pod install
```

## 🤝 Contributing

1. Choose the appropriate flavor for your development
2. Make sure to test both environments before submitting PR
3. Update configuration in `app_config.dart` if adding new environment variables

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
