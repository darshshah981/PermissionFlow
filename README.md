# PermissionFlow

PermissionFlow is an open-source macOS permission onboarding kit for apps that need users to grant privacy permissions in System Settings.

It is designed for developer tools, automation products, AI assistants, screen tools, backup utilities, and other Mac apps where the default permission experience is too confusing.

The core UX:

1. Explain the permission in plain language.
2. Open the correct System Settings pane.
3. Move the main app out of the way.
4. Show a small floating guide beside System Settings.
5. Let the user drag the app icon into the permission list when macOS requires manual adding.
6. Poll the real permission state and mark the step complete automatically.

## Why This Exists

macOS privacy permissions are powerful but hard to explain. Users often get dropped into System Settings with no context, no live progress, and no obvious way back.

PermissionFlow wraps that moment in a calm product experience without bypassing macOS controls. The user still grants every permission manually.

## Install

Add this package to your Swift Package dependencies:

```swift
.package(url: "https://github.com/darshshah981/PermissionFlow.git", from: "0.1.0")
```

Then add `PermissionFlow` to your app target.

## Quick Start

```swift
import PermissionFlow
import SwiftUI

struct SetupView: View {
    @StateObject private var model = PermissionFlowModel(
        steps: [
            MacPermission.screenRecording(),
            MacPermission.accessibility(),
            MacPermission.automation()
        ]
    )

    var body: some View {
        PermissionFlowView(model: model)
    }
}
```

When the user clicks a permission button, PermissionFlow opens System Settings, sends the main app window behind it, and shows a floating guide panel with your app icon.

## Built-In Permissions

PermissionFlow currently includes starter definitions for:

- Screen Recording
- Accessibility
- Automation
- Full Disk Access

Screen Recording and Accessibility use real system checks:

- `CGPreflightScreenCaptureAccess()`
- `AXIsProcessTrusted()`

PermissionFlow intentionally opens System Settings directly instead of calling request APIs like `CGRequestScreenCaptureAccess()` or `AXIsProcessTrustedWithOptions(...)` from the grant button. That avoids the awkward double-prompt experience where macOS shows an "Open System Settings / Deny" sheet while your app also opens Settings.

Automation and Full Disk Access are harder to verify generically because macOS handles them through target-app prompts or broad TCC state that third-party apps cannot reliably inspect. PermissionFlow still provides guided settings UX for those cases, and apps can replace `checkStatus` with their own capability test.

## Custom Permission Step

```swift
let customStep = PermissionStep(
    id: "microphone",
    title: "Allow microphone access",
    shortTitle: "Microphone",
    reason: "Let the app capture audio when recording is active.",
    reassurance: "Audio is only used while recording is turned on.",
    actionTitle: "Open Microphone Settings",
    waitingTitle: "Turn on Microphone",
    waitingDetail: "Enable this app in Privacy & Security -> Microphone.",
    successTitle: "Microphone access is ready.",
    troubleshooting: "If the app is missing, restart it and try again.",
    openSettings: {
        MacPermission.openPrivacyPane("Privacy_Microphone")
    },
    checkStatus: {
        // Return .granted after your app's own permission check.
        .waitingForUser
    }
)
```

## Design Principles

- Be plain-spoken. Avoid framework names like TCC, AX, or Apple Events in user copy.
- Confirm success automatically. Do not make users click "I did it."
- Keep the guide small. System Settings should remain the main focus.
- Separate capability from consent. Even after permissions are granted, ask before risky actions.
- Prefer folder-scoped access over Full Disk Access whenever possible.

## Run the Demo

```bash
swift run PermissionFlowDemo
```

The demo is a minimal SwiftUI app target included in this package.

Note: real privacy grants are most meaningful from a signed `.app` bundle. `swift run PermissionFlowDemo` is useful for development, but a packaged app is the right way to evaluate the full System Settings behavior.

## Current Limitations

- System Settings deep links vary slightly across macOS releases. Always include fallback copy.
- Full Disk Access cannot be reliably preflighted for every app. Use a concrete file capability test when possible.
- Automation permissions are granted per target app. Trigger a real target-app action to produce the native macOS prompt.
- Dragging the app icon into System Settings depends on the target settings list accepting app-bundle drops on that macOS version.

## License

MIT
