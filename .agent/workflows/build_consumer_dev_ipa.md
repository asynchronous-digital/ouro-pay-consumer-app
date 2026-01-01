---
description: Specific process for building the Development IPA for OUROPAY Consumer App
---

# OUROPAY Consumer Dev Build Process

This process ensures the IPA is built correctly for TestFlight with the Development configuration, bypassing scheme issues and deployment target conflicts.

## 1. App Configuration
- **Display Name**: `OUROPAY consumer dev`
- **Bundle ID**: `com.ouropay.consumer.development`
- **Version**: Increment in `pubspec.yaml` (e.g., `1.0.2+1`)

## 2. Configuration Files Setup
Ensure these specific settings are in place:

### `ios/Flutter/Release.xcconfig`
Must include the following to override the default release build:
```xcconfig
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"
#include "Generated.xcconfig"

APP_DISPLAY_NAME=OUROPAY consumer dev
APP_BUNDLE_ID=com.ouropay.consumer.development
```

### `ios/Podfile`
Must force iOS 13.0 to avoid deployment target conflicts:
```ruby
platform :ios, '13.0'

# ... (rest of file)

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

## 3. Build Command
Run this exact command to ensure locale compatibility and correct flavor defines:

// turbo
```bash
export LANG=en_US.UTF-8 && export LC_ALL=en_US.UTF-8 && fvm flutter clean && fvm flutter pub get && cd ios && pod install && cd .. && fvm flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define=FLAVOR=development
```

## 4. Output
The resulting IPA will be at `build/ios/ipa/ouro_pay_consumer_app.ipa`.
Upload this file via the **Transporter** app.
