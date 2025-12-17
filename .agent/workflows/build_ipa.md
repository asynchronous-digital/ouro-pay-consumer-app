---
description: Build IPA for TestFlight/App Store Distribution (Reusable Workflow)
---

This workflow outlines the robust process to build an IPA file for Flutter iOS apps, ensuring correct Bundle IDs and Display Names via `xcconfig`.

# 1. Versioning
- Open `pubspec.yaml`
- Increment the `version`: e.g., `1.0.1+2`

# 2. Key Configuration (Crucial Step)
Ensure your build configurations define the correct App Name and Bundle ID. This prevents the app from reverting to "Runner" or the wrong ID.

- **Check `ios/Flutter/Release.xcconfig`** (and `Debug.xcconfig` for local testing):
  ```xcconfig
  APP_DISPLAY_NAME=Your App Name
  APP_BUNDLE_ID=com.example.your.bundle.id
  ```
  *(Make sure these match your target distribution profile)*

# 3. Export Options
Ensure `ios/ExportOptions.plist` exists with the correct Team ID:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string> <!-- or 'ad-hoc', 'development' -->
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

# 4. Build Command
Run the following to clean and build:

```bash
# 1. Clean environment
fvm flutter clean
fvm flutter pub get
cd ios && pod install && cd ..

# 2. Build IPA
fvm flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

# 5. Output
- The IPA will be at: `build/ios/ipa/ouro_pay_consumer_app.ipa` (or project name).

# 6. Upload
- Open **Transporter** app (macOS).
- Drag and drop the generated `.ipa` file.
- Click **Deliver**.
