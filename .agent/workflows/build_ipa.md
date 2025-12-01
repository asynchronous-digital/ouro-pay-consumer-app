---
description: Build IPA for TestFlight/App Store Distribution
---

This workflow describes how to build an IPA file for TestFlight or App Store distribution, specifically handling the `com.ouropay.consumer.development` bundle ID and Team ID `PC8N5PX8LJ`.

# Prerequisites

1.  **Certificates**: Ensure you have a valid **Apple Distribution Certificate** in your Keychain for Team `PC8N5PX8LJ`.
2.  **Provisioning Profiles**: Ensure Xcode has created/downloaded the necessary provisioning profiles (usually handled automatically by Xcode if the Team ID is correct).
3.  **ExportOptions.plist**: Ensure `ios/ExportOptions.plist` exists and is configured correctly.

# Configuration Check

1.  **Bundle ID**: Verify `PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj` is set to `com.ouropay.consumer.development` (or your target bundle ID).
2.  **Team ID**: Verify `DEVELOPMENT_TEAM` in `ios/Runner.xcodeproj/project.pbxproj` is set to `PC8N5PX8LJ`.
3.  **Version/Build**: Increment the version/build number in `pubspec.yaml` (e.g., `version: 1.0.0+2`).

# ExportOptions.plist Content

Ensure `ios/ExportOptions.plist` contains the following (adjust Team ID if needed):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store</string>
	<key>teamID</key>
	<string>PC8N5PX8LJ</string>
	<key>uploadBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
	<key>compileBitcode</key>
	<false/>
	<key>signingStyle</key>
	<string>automatic</string>
</dict>
</plist>
```

# Build Command

Run the following command to clean, build the archive, and export the IPA:

```bash
# 1. Clean (Optional but recommended)
fvm flutter clean
fvm flutter pub get
cd ios && pod install && cd ..

# 2. Build IPA
fvm flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

# Upload

1.  Open **Transporter** app.
2.  Drag and drop the generated IPA file from `build/ios/ipa/*.ipa`.
3.  Click **Deliver**.
