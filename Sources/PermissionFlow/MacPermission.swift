import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

public enum MacPermission {
    public static func accessibility() -> PermissionStep {
        PermissionStep(
            id: "accessibility",
            title: "Allow computer control",
            shortTitle: "Computer control",
            reason: "Let this app click buttons, type text, and navigate other apps when you ask it to.",
            reassurance: "You stay in control. Your app can still ask again before sensitive actions like sending messages, deleting files, or submitting forms.",
            actionTitle: "Open Accessibility Settings",
            waitingTitle: "Turn on Accessibility",
            waitingDetail: "In System Settings, enable this app in Privacy & Security -> Accessibility. If it is not listed, drag the app icon into the list.",
            successTitle: "Computer control is ready.",
            troubleshooting: "If the app does not appear, quit and reopen it once, then try again. Some macOS versions require adding the app with the plus button.",
            guideSteps: [
                "Turn on this app.",
                "If it is missing, drag this icon into the list."
            ],
            allowsAppIconDrag: true,
            openSettings: {
                openPrivacyPane("Privacy_Accessibility")
            },
            checkStatus: {
                AXIsProcessTrusted() ? .granted : .waitingForUser
            }
        )
    }

    public static func screenRecording() -> PermissionStep {
        PermissionStep(
            id: "screen-recording",
            title: "Allow screen access",
            shortTitle: "Screen access",
            reason: "Let this app understand what is visible on the screen while computer assistance is active.",
            reassurance: "Screen access is only a capability grant. Your product should still make it clear when assistance is running.",
            actionTitle: "Open Screen Recording Settings",
            waitingTitle: "Turn on Screen Recording",
            waitingDetail: "In System Settings, enable this app in Privacy & Security -> Screen & System Audio Recording. You may need to quit and reopen the app afterward.",
            successTitle: "Screen access is ready.",
            troubleshooting: "If macOS asks to restart the app, quit and reopen it after enabling the permission.",
            guideSteps: [
                "Turn on this app.",
                "If it is missing, drag this icon into the list.",
                "If macOS asks, quit and reopen the app."
            ],
            allowsAppIconDrag: true,
            openSettings: {
                openPrivacyPane("Privacy_ScreenCapture")
            },
            checkStatus: {
                CGPreflightScreenCaptureAccess() ? .granted : .waitingForUser
            }
        )
    }

    public static func automation() -> PermissionStep {
        PermissionStep(
            id: "automation",
            title: "Allow app automation",
            shortTitle: "App automation",
            reason: "Let this app communicate with selected apps when a task needs app-specific automation.",
            reassurance: "macOS asks separately for each target app the first time automation is used.",
            actionTitle: "Open Automation Settings",
            waitingTitle: "Review Automation Access",
            waitingDetail: "In System Settings, review which apps this app can control. Automation prompts usually appear when a specific target app is used.",
            successTitle: "Automation settings are available.",
            troubleshooting: "If no target app appears yet, run a task that uses the target app. macOS will show the permission prompt at that moment.",
            guideSteps: [
                "Review the apps listed under this app.",
                "Approve target apps when macOS prompts."
            ],
            openSettings: {
                openPrivacyPane("Privacy_Automation")
            },
            checkStatus: {
                .granted
            }
        )
    }

    public static func fullDiskAccess() -> PermissionStep {
        PermissionStep(
            id: "full-disk-access",
            title: "Allow full disk access",
            shortTitle: "Full disk access",
            reason: "Let this app access protected folders only if your product truly needs broad file visibility.",
            reassurance: "Prefer folder-scoped access for most apps. Full Disk Access should be reserved for developer tools, backup tools, and security tools.",
            actionTitle: "Open Full Disk Access Settings",
            waitingTitle: "Turn on Full Disk Access",
            waitingDetail: "In System Settings, enable this app in Privacy & Security -> Full Disk Access. If it is not listed, drag the app icon into the list.",
            successTitle: "Full Disk Access is ready.",
            troubleshooting: "Full Disk Access may require a restart before every protected location becomes readable.",
            guideSteps: [
                "Turn on this app.",
                "If it is missing, drag this icon into the list."
            ],
            allowsAppIconDrag: true,
            isRequired: false,
            openSettings: {
                openPrivacyPane("Privacy_AllFiles")
            },
            checkStatus: {
                .waitingForUser
            }
        )
    }

    @MainActor
    public static func openPrivacyPane(_ anchor: String) {
        let modern = "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
        guard let url = URL(string: modern) else { return }
        NSWorkspace.shared.open(url)
    }
}
