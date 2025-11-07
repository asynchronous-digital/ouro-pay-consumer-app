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
- Flutter SDK (latest stable version)
- Dart SDK  
- Android Studio / Xcode (for device testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ouro_pay_consumer_app
   ```

2. **Set up environment configuration**
   ```bash
   # Copy example to create your environment files
   cp .env.example .env.development
   cp .env.example .env.production
   
   # Update each file with your actual configuration values
   # Edit .env.development and .env.production with your API keys, URLs, etc.
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   # or
   make deps
   ```

4. **Verify Flutter installation**
   ```bash
   flutter doctor
   # or  
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

### Using Flutter Commands

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
# Development APK
make build-dev-android
# or
flutter build apk --flavor development --target lib/main_dev.dart

# Production APK  
make build-prod-android
# or
flutter build apk --flavor production --target lib/main_prod.dart
```

### iOS

```bash
# Development IPA
make build-dev-ios
# or  
flutter build ios --flavor development --target lib/main_dev.dart --no-codesign

# Production IPA
make build-prod-ios
# or
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

## 🔧 Available Make Commands

Run `make help` to see all available commands:

- `make deps` - Get Flutter dependencies
- `make clean` - Clean build files  
- `make doctor` - Run Flutter doctor
- `make dev` - Run development flavor
- `make prod` - Run production flavor
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

## 🤝 Contributing

1. Choose the appropriate flavor for your development
2. Make sure to test both environments before submitting PR
3. Update configuration in `app_config.dart` if adding new environment variables

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
