# Ouro Pay Consumer App

A Flutter application with development and production environment support using flavors.

## 🚀 Quick Start for Developers

### New to this project? Follow these steps:

1. **Install FVM (if you don't have it)**
   ```bash
   # macOS
   brew install fvm
   
   # Other platforms
   dart pub global activate fvm
   ```

2. **Clone and setup the project**
   ```bash
   git clone https://github.com/asynchronous-digital/ouro-pay-consumer-app.git
   cd ouro-pay-consumer-app
   
   # Install the exact Flutter version for this project
   fvm install
   fvm use
   
   # Get dependencies
   fvm flutter pub get
   ```

3. **Run the app (Development)**
   ```bash
   # Quick run development version
   fvm flutter run --flavor development --target lib/main_dev.dart
   
   # Or use Make command
   make dev
   ```

4. **That's it!** 🎉 The app should now be running on your device/emulator.

---

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

### 📱 FVM Setup (Recommended for Team Development)

This project uses **FVM (Flutter Version Manager)** to ensure ALL developers use the same Flutter version (3.35.7).

#### Why FVM?
- ✅ **Same version for everyone** - No "works on my machine" issues
- ✅ **Automatic version switching** - Project sets its own Flutter version
- ✅ **Multiple Flutter versions** - Work on different projects with different Flutter versions
- ✅ **CI/CD consistency** - Same version locally and in builds

#### Step-by-Step FVM Installation

**Step 1: Install FVM**
```bash
# macOS (Recommended)
brew install fvm

# Windows/Linux/Alternative
dart pub global activate fvm

# Verify installation
fvm --version
```

**Step 2: Install Project's Flutter Version**
```bash
# Navigate to project directory first
cd ouro-pay-consumer-app

# Install Flutter 3.35.7 (reads from .fvmrc file)
fvm install

# Set this version for the project
fvm use

# Verify it's working
fvm flutter --version
# Should show: Flutter 3.35.7
```

**Step 3: Setup Your IDE**
```bash
# VS Code: FVM automatically configures the Flutter SDK path
# Android Studio: Set Flutter SDK path to:
# ~/.fvm/versions/3.35.7 (macOS/Linux)
# %USERPROFILE%\.fvm\versions\3.35.7 (Windows)
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

## 💻 Common Developer Tasks

### 🔄 Daily Workflow Commands
```bash
# Start developing (most common command)
fvm flutter run --flavor development --target lib/main_dev.dart

# Get latest code and dependencies
git pull
fvm flutter pub get

# Clean build when things get weird
fvm flutter clean
fvm flutter pub get

# Check what devices are available
fvm flutter devices

# View app logs
fvm flutter logs
```

### 🔧 When You Change Dependencies
```bash
# After modifying pubspec.yaml
fvm flutter pub get

# If you added native dependencies, clean build
fvm flutter clean
fvm flutter pub get
```

### 🏗️ Building for Testing
```bash
# Debug builds (for development/testing)
fvm flutter build apk --flavor development --target lib/main_dev.dart --debug
fvm flutter build apk --flavor production --target lib/main_prod.dart --debug

# Release builds (for distribution)
fvm flutter build apk --flavor development --target lib/main_dev.dart
fvm flutter build apk --flavor production --target lib/main_prod.dart
```

## 🏃‍♂️ Running the App

### 🎯 Daily Development Commands

```bash
# 🚀 Most common: Run development version
fvm flutter run --flavor development --target lib/main_dev.dart

# 🔥 With hot reload (auto-restart on code changes)
fvm flutter run --flavor development --target lib/main_dev.dart --hot

# 📱 Run on specific device (list devices first)
fvm flutter devices
fvm flutter run --flavor development --target lib/main_dev.dart -d <device-id>

# 🏭 Run production version (for testing production build)
fvm flutter run --flavor production --target lib/main_prod.dart
```

### 🛠️ Using Make Commands (Easiest)

```bash
# ⚡ Super quick commands (uses FVM automatically)
make dev          # Run development
make prod         # Run production
make dev-ios      # Run development on iOS
make prod-ios     # Run production on iOS
make clean        # Clean build files
make deps         # Get dependencies
```

### 📋 All FVM Commands You'll Need

```bash
# Basic app commands
fvm flutter run --flavor development --target lib/main_dev.dart
fvm flutter run --flavor production --target lib/main_prod.dart

# Development helpers
fvm flutter clean                    # Clean build cache
fvm flutter pub get                  # Get dependencies
fvm flutter doctor                   # Check Flutter setup
fvm flutter devices                  # List connected devices
fvm flutter logs                     # View app logs

# Building
fvm flutter build apk --flavor development --target lib/main_dev.dart
fvm flutter build apk --flavor production --target lib/main_prod.dart
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

## 🔍 Troubleshooting for New Developers

### 🚨 "FVM not found" or "command not found"

```bash
# Step 1: Install FVM properly
brew install fvm  # macOS
# OR
dart pub global activate fvm

# Step 2: Add to PATH (if using dart pub global)
echo 'export PATH="$PATH":"$HOME/.pub-cache/bin"' >> ~/.zshrc
source ~/.zshrc

# Step 3: Verify installation
fvm --version
```

### 🚨 "Flutter version is wrong" or "No version set"

```bash
# Make sure you're in the project directory
cd ouro-pay-consumer-app

# Check if .fvmrc file exists (should contain "3.35.7")
cat .fvmrc

# Install the correct version
fvm install 3.35.7
fvm use 3.35.7

# Verify it's set correctly
fvm flutter --version  # Should show 3.35.7
```

### 🚨 "Build failed" or Gradle errors

```bash
# Nuclear option - clean everything and start fresh
fvm flutter clean
rm -rf build/
fvm flutter pub get
fvm flutter run --flavor development --target lib/main_dev.dart
```

### 🚨 iOS build issues (Mac only)

```bash
# Clean iOS dependencies
cd ios
rm -rf Pods/ Podfile.lock
pod install
cd ..

# Clean Flutter
fvm flutter clean
fvm flutter pub get

# Try building again
fvm flutter run --flavor development --target lib/main_dev.dart
```

### 🚨 "No devices found"

```bash
# List available devices
fvm flutter devices

# For Android: Make sure device is connected and USB debugging is ON
# For iOS: Make sure device is trusted and Xcode is set up
# For simulators: Open Android Studio or Xcode to start simulators
```

### 🚨 Still having issues?

1. **Check Flutter setup**: `fvm flutter doctor`
2. **Ask for help**: Include the error message and what you tried
3. **Check Flutter version**: `fvm flutter --version` should show `3.35.7`

## ✅ First Time Setup Checklist

Use this checklist to verify your setup is correct:

```bash
# □ 1. FVM is installed
fvm --version
# Should show FVM version (e.g., 3.0.0)

# □ 2. Project Flutter version is installed
fvm flutter --version
# Should show: Flutter 3.35.7

# □ 3. Dependencies are installed
fvm flutter pub get
# Should complete without errors

# □ 4. Flutter doctor passes
fvm flutter doctor
# Should show mostly green checkmarks

# □ 5. Device/emulator is connected
fvm flutter devices
# Should show at least one device

# □ 6. App runs successfully
fvm flutter run --flavor development --target lib/main_dev.dart
# Should build and run the OURO PAY app
```

### ✅ What Success Looks Like

When everything is working correctly, you should see:
- **App launches** with "Ouro Pay Dev" title
- **Gold theme** with black/gold colors
- **Welcome page** with OURO PAY logo and "Get Started" button
- **No error messages** in the console

## 🤝 Contributing

### For New Developers
1. **Follow the Quick Start guide** above
2. **Use FVM commands** instead of regular flutter commands
3. **Test both flavors** before submitting PR:
   ```bash
   make dev    # Test development flavor
   make prod   # Test production flavor
   ```

### For All Contributors
1. Choose the appropriate flavor for your development
2. Make sure to test both environments before submitting PR
3. Update configuration in `app_config.dart` if adding new environment variables
4. Always use FVM commands to maintain version consistency

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
