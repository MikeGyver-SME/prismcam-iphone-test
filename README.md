# PrismCam — native iPhone install experiment

An actual SwiftUI iPhone app. Open the camera, take a picture, switch among Original, Noir, Warm, and Vivid, and save the result to Photos. The picture stays on your phone; this app makes no network requests.

## What this package does

GitHub Actions uses a macOS runner with Xcode to compile the app and uploads **PrismCam-unsigned.ipa** as a workflow artifact. That IPA is deliberately unsigned: your Apple Account is used only on your own Windows PC during installation. No Apple credentials or certificates belong in the repository or GitHub Actions secrets.

This is a proof-of-install workflow. The unsigned IPA's acceptance by your chosen Windows signing tool has **not yet been verified** on your device. If its installer rejects this IPA, the build log and installer error will guide the packaging adjustment.

## Build it in your GitHub account

1. Create a new repository, for example `prismcam-iphone-test`. A public repository gets standard GitHub-hosted Actions usage without billed minutes; a private repository uses your plan's included minutes and may incur charges after its allowance. Check your GitHub billing settings before selecting private.
2. Unzip this project and push **the contents of the `PrismCam` directory** to the repository's `main` branch. The `.github` directory must be included (on Windows, enable viewing hidden items if needed).
3. In the repository, open **Actions → Build iPhone IPA → Run workflow**. A push to `main` also starts a build.
4. When the job succeeds, open that run's **Artifacts** and download `PrismCam-unsigned-ipa`. Unzip the artifact download to find `PrismCam-unsigned.ipa`. GitHub retains the artifact for 14 days.

If this workflow uses a newer Xcode image in future, pin an available macOS runner or select an Xcode version in the workflow. The app itself targets iOS 17 or later.

## Install from Windows

1. Install Sideloadly from its official site: https://sideloadly.io/ . Follow its Windows prerequisites, connect your iPhone, and select `PrismCam-unsigned.ipa`.
2. Sign and install using your Apple Account **on your PC**. Never paste its password into GitHub, this app, or a chat. Follow Sideloadly's prompts for two-factor authentication and device trust.
3. Enable Developer Mode on the iPhone if iOS requests it; follow the on-device prompts and restart.
4. Open PrismCam, grant camera access, take a photo, select a look, and grant Photos *add-only* access when you tap Save.
5. On a free Apple Account, expect to refresh or reinstall the app every seven days. Sideloadly documents automatic refresh when configured.

This app is not yet built or tested on a macOS runner or physical iPhone. A successful GitHub run confirms the compilation, and a successful launch and save on your device confirms the complete path.

## Project files

- `Sources/PrismCamApp.swift`: SwiftUI entry point.
- `Sources/StudioView.swift`: camera, Core Image looks, Photos save, and interface.
- `project.yml`: XcodeGen project specification and iOS permission strings.
- `.github/workflows/ios-build.yml`: macOS build and unsigned IPA artifact.

`project.yml` can be generated locally on a Mac with `brew install xcodegen && xcodegen generate`, though you do not need a Mac for the hosted workflow.
