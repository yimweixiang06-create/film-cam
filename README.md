# FilmStyleCamera — iOS 18+ starter project

## Important status

This is a starter source project, **not a finished or device-tested app**. It demonstrates:
- iOS 18 deployment target
- AVFoundation camera preview and photo capture
- photo saving to Photos
- a touch/drag dot palette
- basic Core Image style approximations and Fuji/Kodak-inspired presets
- iOS 26 Liquid Glass API guarded by availability, with a material fallback on iOS 18–25

It does **not yet implement a working video recording pipeline**, filtered live preview, true portrait/panorama modes, or Apple's proprietary native Photographic Styles rendering. The mode labels for those features are UI placeholders. The style names and renderings are approximations and must be checked against the exact iPhone model and iOS version. Do not advertise this build as an Apple-identical clone.

## Build requirements

- A Mac with Xcode 26 or later is recommended (the source references the iOS 26 `glassEffect` API under an availability check).
- iOS 18+ deployment target.
- A real iPhone is recommended for camera testing. Simulator camera behavior is limited.
- An Apple ID for signing. Paid Apple Developer membership is normally needed for App Store/TestFlight distribution; local device signing may work with a free account and restrictions.

## Open and build

1. Unzip the project on a Mac.
2. Open `FilmStyleCamera.xcodeproj` in Xcode.
3. Select target `FilmStyleCamera`, then **Signing & Capabilities**.
4. Choose your Team and change the Bundle Identifier to a unique value, e.g. `com.yourname.FilmStyleCamera`.
5. Set deployment target to iOS 18.0.
6. Select a connected iPhone and press Run. Approve camera/microphone/Photos permissions.
7. Resolve any Xcode build errors before making an IPA. This source archive has not been compiled in this environment.

## Export an IPA

### Xcode GUI (recommended)
1. Choose **Any iOS Device (arm64)** as the run destination.
2. Choose **Product → Archive**.
3. When Organizer opens, select the archive and choose **Distribute App**.
4. For your own device, select **Development** (or Ad Hoc if your account/profile supports it). For beta testing, choose **TestFlight / App Store Connect**.
5. Follow signing/profile prompts, then export the IPA if that distribution method offers an IPA export.

### Command line (after configuring signing)
```bash
xcodebuild -project FilmStyleCamera.xcodeproj \
  -scheme FilmStyleCamera \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/FilmStyleCamera.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath build/FilmStyleCamera.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```
Create `ExportOptions.plist` with the correct `method`, `teamID`, and signing settings for your Apple Developer account. The exact method options depend on your installed Xcode version and distribution type.

## Can this be done on iPad only?

An iPad alone generally cannot run Xcode or sign a normal iOS IPA locally. You can use a cloud Mac/build service or GitHub Actions with macOS runners, but signing certificates and provisioning profiles still need to be configured securely. Never share your Apple ID password or signing private key in chat.

## Architecture notes

- `CameraModel.swift`: AVFoundation camera session, capture, and Photos saving.
- `FilterEngine.swift`: Core Image approximations applied to captured stills.
- `DotPalette.swift`: interactive point-grid control.
- `CameraHomeView.swift`: UI and bottom mode strip.

Before calling this production-ready, implement and test filtered live preview, AVAssetWriter-based video recording with synchronized audio/video processing, true mode-specific capture behavior, orientation handling, front-camera mirroring, flash support, error recovery, and exact style reference comparisons.
