# iOS Share Extension Setup Guide

This guide documents the manual Xcode configuration required to enable iOS Share Extension support for the Fin app. Unlike Android, iOS Share Extensions cannot be configured via CLI or Flutter configuration files alone and require manual Xcode setup.

## Overview

iOS Share Extensions allow users to share content from other apps (like Photos, Camera, Files) directly to the Fin app. When a user shares an image to Fin, the app will launch and navigate to the Receipt Review screen with the shared image ready for processing.

## Prerequisites

- macOS with Xcode 14.0 or later installed
- Apple Developer account (free or paid)
- Familiarity with Xcode project configuration
- The `receive_sharing_intent` Flutter package (already added to pubspec.yaml)

## Step 1: Open the iOS Project in Xcode

1. Navigate to the Fin project root directory
2. Open the iOS workspace file:
   ```bash
   open ios/Runner.xcworkspace
   ```
   > **Important**: Open the `.xcworkspace` file, not the `.xcodeproj` file, to ensure CocoaPods dependencies are included.

## Step 2: Create the Share Extension Target

1. In Xcode, go to **File** > **New** > **Target...**
2. Select **iOS** from the platform tabs
3. Choose **Share Extension** from the template list
4. Click **Next**
5. Configure the extension:
   - **Product Name**: `ShareExtension`
   - **Team**: Select your development team
   - **Language**: Swift
   - **Include UI Extension**: Leave unchecked (not needed for image sharing)
6. Click **Finish**
7. When prompted to activate the scheme, click **Cancel** (we'll use the main Runner scheme)

## Step 3: Configure App Groups

App Groups allow the Share Extension (which runs in a separate process) to communicate with the main app.

### Create an App Group

1. Select the **Runner** project in the Project Navigator
2. Select the **Runner** target
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **App Groups**
6. Click the **+** button to add a new group
7. Enter a group identifier (e.g., `group.com.yourcompany.fin`)
   > Use the format: `group.{your-bundle-identifier}`

### Add App Group to Share Extension

1. Select the **ShareExtension** target
2. Go to the **Signing & Capabilities** tab
3. Click **+ Capability** and add **App Groups**
4. Select the **same App Group** you created above

### Verify Team ID Matching

Ensure both targets use the same Apple Developer Team:

1. Select **Runner** target > **Signing & Capabilities**
2. Note the **Team** selected
3. Select **ShareExtension** target > **Signing & Capabilities**
4. Verify the same **Team** is selected

## Step 4: Configure Share Extension Info.plist

Update the Share Extension's `Info.plist` to accept image files:

1. In the Project Navigator, expand **ShareExtension** folder
2. Open `Info.plist`
3. Add or modify the `NSExtension` dictionary with the following configuration:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsMovieWithMaxCount</key>
            <integer>0</integer>
        </dict>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
</dict>
```

**Key configuration options:**

| Key | Value | Description |
|-----|-------|-------------|
| `NSExtensionActivationSupportsImageWithMaxCount` | `10` | Max images accepted (set to 1 for single image only) |
| `NSExtensionActivationSupportsMovieWithMaxCount` | `0` | Disabled for video (receipt scanning is image-only) |
| `NSExtensionPointIdentifier` | `com.apple.share-services` | Registers as a share extension |

## Step 5: Update ShareViewController.swift

Replace the contents of `ShareExtension/ShareViewController.swift` with code that works with `receive_sharing_intent`:

```swift
import UIKit
import Social
import MobileCoreServices
import Photos

class ShareViewController: SLComposeServiceViewController {

    let hostAppBundleIdentifier = "com.yourcompany.fin"
    let sharedKey = "ShareKey"
    var sharedMedia: [SharedMediaFile] = []

    override func isContentValid() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didSelectPost() {
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in (contents).enumerated() {
                    if attachment.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                        handleImages(content: content, attachment: attachment, index: index)
                    }
                }
            }
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }

    private func handleImages(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { [weak self] data, error in
            guard let self = self else { return }

            if error == nil, let url = data as? URL {
                self.sharedMedia.append(SharedMediaFile(path: url.absoluteString, type: .image))
            }

            if index == (content.attachments?.count ?? 0) - 1 {
                self.saveToAppGroup()
            }
        }
    }

    private func saveToAppGroup() {
        let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.fin")
        let jsonEncoder = JSONEncoder()

        if let json = try? jsonEncoder.encode(sharedMedia) {
            userDefaults?.set(json, forKey: sharedKey)
        }

        userDefaults?.synchronize()
        self.redirectToHostApp()
    }

    private func redirectToHostApp() {
        let url = URL(string: "\(hostAppBundleIdentifier)://dataUrl=\(sharedKey)")!
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")

        while (responder != nil) {
            if responder?.responds(to: selectorOpenURL) == true {
                responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder!.next
        }

        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
}

class SharedMediaFile: Codable {
    var path: String
    var type: SharedMediaType

    init(path: String, type: SharedMediaType) {
        self.path = path
        self.type = type
    }
}

enum SharedMediaType: Int, Codable {
    case image
    case video
    case file
}
```

> **Important**: Replace `com.yourcompany.fin` with your actual bundle identifier in both `hostAppBundleIdentifier` and the App Group name.

## Step 6: Update Main App Info.plist

Add URL scheme handling to the main Runner app's `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourcompany.fin</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.fin</string>
    </dict>
</array>
```

## Step 7: Configure receive_sharing_intent for iOS

The `receive_sharing_intent` package handles the Flutter-side integration. Ensure the following is configured in `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Access photos to import receipts for scanning</string>
```

## Step 8: Build and Test

1. Select the **Runner** target and your iOS device/simulator
2. Build and run the app: **Product** > **Run** (Cmd+R)
3. Once installed, test the share extension:
   - Open the Photos app
   - Select an image
   - Tap the Share button
   - Scroll to find "Fin" in the share sheet
   - Tap "Fin" to share

## Known Limitations

### Memory Limit
- Share Extensions have a **~120MB memory limit**
- Large images may need compression before processing
- The extension will be terminated if it exceeds memory limits

### Separate Process
- Extensions run in a **separate process** from the main app
- Cannot directly access main app's memory or state
- Must use App Groups for data sharing

### Processing Time
- Extensions have limited execution time (~30 seconds)
- Long-running operations may be terminated by the system
- Image data should be passed to main app for heavy processing

### UI Limitations
- Share Extensions use a standardized UI (SLComposeServiceViewController)
- Custom UI requires using a different base class (UIViewController)
- Customization options are limited compared to the main app

## Troubleshooting

### Share Extension Not Appearing

1. **Verify Bundle Identifier**: Ensure the extension's bundle ID is a child of the main app's bundle ID (e.g., `com.yourcompany.fin.ShareExtension`)

2. **Check Signing**: Both targets must use the same Team ID

3. **Clean Build**:
   ```bash
   cd ios
   rm -rf build/
   pod deintegrate
   pod install
   ```
   Then rebuild from Xcode

4. **Device Restart**: Sometimes iOS caches extension availability; restart the device

### App Group Communication Failing

1. **Verify App Group Names Match**: The group identifier must be identical in both targets

2. **Check Capabilities**: Ensure App Groups capability is properly added to both targets

3. **Entitlements File**: Verify the `.entitlements` files contain the correct App Group

### Extension Crashes on Image Load

1. **Memory Issues**: Try compressing images or processing smaller batches

2. **File Access**: Ensure the extension has permission to access the shared file

3. **Check Logs**: Use Xcode's Console to view extension crash logs:
   ```
   Product > Scheme > Edit Scheme > Run > Arguments > Add: -NSExtensionProcessLogging YES
   ```

## References

- [Apple Developer: Share Extensions](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Share.html)
- [receive_sharing_intent Package](https://pub.dev/packages/receive_sharing_intent)
- [App Groups Documentation](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [iOS Extension Programming Guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/)

## Checklist

Before testing, verify:

- [ ] Share Extension target created in Xcode
- [ ] App Groups capability added to both Runner and ShareExtension targets
- [ ] Same App Group identifier used in both targets
- [ ] Same Team ID used for signing both targets
- [ ] ShareExtension Info.plist configured with NSExtension settings
- [ ] ShareViewController.swift updated with correct bundle identifier
- [ ] Main app Info.plist has URL scheme configured
- [ ] NSPhotoLibraryUsageDescription added to main app Info.plist
- [ ] Clean build performed
- [ ] Extension appears in share sheet
- [ ] Shared images received by main app
