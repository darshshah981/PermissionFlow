import AppKit
import CoreGraphics
import SwiftUI

@MainActor
public final class PermissionFloatingCoach {
    private enum Layout {
        static let panelSize = NSSize(width: 286, height: 112)
        static let windowGap: CGFloat = 12
        static let screenPadding: CGFloat = 18
        static let introYOffset: CGFloat = -10
    }

    private var panel: NSPanel?
    private var hostingView: NSHostingView<FloatingCoachView>?

    public init() {}

    public func show(for step: PermissionStep, sourceFrame: NSRect? = nil) {
        let view = FloatingCoachView(step: step, isSuccess: false) { [weak self] in
            self?.close()
        }

        if let panel, let hostingView {
            hostingView.rootView = view
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            let frame = targetFrameNearSystemSettings()
            if let sourceFrame {
                animate(panel: panel, from: startingFrame(from: sourceFrame), to: frame)
            } else {
                animate(panel: panel, to: frame)
            }
            return
        }

        let hostingView = NSHostingView(rootView: view)
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Layout.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Permission Guide"
        panel.isFloatingPanel = true
        panel.isRestorable = false
        panel.isOpaque = false
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isMovableByWindowBackground = true
        panel.contentView = hostingView

        let finalFrame = targetFrameNearSystemSettings()
        let introFrame = sourceFrame.map(startingFrame(from:)) ?? finalFrame.offsetBy(dx: 0, dy: Layout.introYOffset)
        panel.setFrame(introFrame, display: false)
        panel.alphaValue = 0

        self.panel = panel
        self.hostingView = hostingView

        panel.orderFrontRegardless()
        animate(panel: panel, to: finalFrame)
    }

    public func updateSuccess(for step: PermissionStep) {
        hostingView?.rootView = FloatingCoachView(step: step, isSuccess: true) { [weak self] in
            self?.close()
        }
        panel?.orderFrontRegardless()
    }

    public func repositionNearSystemSettings(animated: Bool = true) {
        guard let panel else { return }
        let frame = targetFrameNearSystemSettings()

        if animated {
            animate(panel: panel, to: frame)
        } else {
            panel.setFrame(frame, display: true)
        }
    }

    public func close() {
        panel?.close()
        panel = nil
        hostingView = nil
    }

    private func animate(panel: NSPanel, to frame: NSRect) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func animate(panel: NSPanel, from startFrame: NSRect, to endFrame: NSRect) {
        panel.setFrame(startFrame, display: true)
        panel.alphaValue = 0.72

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.32
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(endFrame, display: true)
        }
    }

    private func startingFrame(from sourceFrame: NSRect) -> NSRect {
        let screenFrame = NSScreen.main?.visibleFrame ?? sourceFrame
        let x = min(
            max(sourceFrame.minX + 18, screenFrame.minX + Layout.screenPadding),
            screenFrame.maxX - Layout.panelSize.width - Layout.screenPadding
        )
        let y = min(
            max(sourceFrame.midY - (Layout.panelSize.height / 2), screenFrame.minY + Layout.screenPadding),
            screenFrame.maxY - Layout.panelSize.height - Layout.screenPadding
        )

        return NSRect(x: x, y: y, width: Layout.panelSize.width, height: Layout.panelSize.height)
    }

    private func targetFrameNearSystemSettings() -> NSRect {
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        guard let settingsFrame = systemSettingsWindowFrame() else {
            return NSRect(
                x: screenFrame.maxX - Layout.panelSize.width - Layout.screenPadding,
                y: screenFrame.maxY - Layout.panelSize.height - Layout.screenPadding,
                width: Layout.panelSize.width,
                height: Layout.panelSize.height
            )
        }

        let x = min(
            max(settingsFrame.midX - (Layout.panelSize.width / 2), screenFrame.minX + Layout.screenPadding),
            screenFrame.maxX - Layout.panelSize.width - Layout.screenPadding
        )
        let lowerY = settingsFrame.minY + max(28, settingsFrame.height * 0.16)
        let y = min(
            max(lowerY, screenFrame.minY + Layout.screenPadding),
            screenFrame.maxY - Layout.panelSize.height - Layout.screenPadding
        )

        return NSRect(x: x, y: y, width: Layout.panelSize.width, height: Layout.panelSize.height)
    }

    private func systemSettingsWindowFrame() -> NSRect? {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        let settingsWindow = windows.first { window in
            guard
                let ownerName = window[kCGWindowOwnerName as String] as? String,
                let layer = window[kCGWindowLayer as String] as? Int
            else {
                return false
            }

            return ownerName == "System Settings" && layer == 0
        }

        guard
            let bounds = settingsWindow?[kCGWindowBounds as String] as? [String: CGFloat],
            let x = bounds["X"],
            let y = bounds["Y"],
            let width = bounds["Width"],
            let height = bounds["Height"],
            let screen = NSScreen.main
        else {
            return nil
        }

        // CoreGraphics reports window bounds from the top-left display origin.
        // AppKit window frames use a bottom-left origin.
        let appKitY = screen.frame.maxY - y - height
        return NSRect(x: x, y: appKitY, width: width, height: height)
    }
}

private struct FloatingCoachView: View {
    let step: PermissionStep
    let isSuccess: Bool
    let onClose: () -> Void

    private var guideSteps: [String] {
        step.guideSteps.isEmpty
            ? [
                "Turn on this app.",
                "If it is missing, drag this icon into the list."
            ]
            : step.guideSteps
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 9) {
                    CoachAppIcon(isDraggable: step.allowsAppIconDrag)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isSuccess ? "Permission ready" : step.shortTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        Text(isSuccess ? "Return to the app." : "Finish in System Settings.")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }

                if isSuccess {
                    Text(step.successTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(guideSteps, id: \.self) { text in
                            GuideLine(text: text)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.leading, 24)
            .padding(.trailing, 28)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close")
            .padding(.trailing, 9)
            .padding(.top, 9)
        }
        .frame(width: 286, height: 112)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CoachAppIcon: View {
    let isDraggable: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            DraggableAppIcon(isDraggable: isDraggable)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    if isDraggable {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.55), lineWidth: 1)
                    }
                }

            if isDraggable {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 13, height: 13)
                    .background(Circle().fill(Color.accentColor))
                    .offset(x: 4, y: 4)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: isDraggable ? 34 : 28, height: isDraggable ? 34 : 28, alignment: .topLeading)
        .help(isDraggable ? "Drag this app into the permission list if it is missing." : "")
    }
}

private struct GuideLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(0.82))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
