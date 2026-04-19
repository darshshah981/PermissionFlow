import AppKit
import SwiftUI

public struct PermissionFlowView: View {
    @ObservedObject private var model: PermissionFlowModel
    @State private var rowFrames: [String: NSRect] = [:]

    public init(model: PermissionFlowModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            VStack(spacing: 10) {
                ForEach(model.steps) { step in
                    PermissionStepRow(
                        step: step,
                        state: model.state(for: step),
                        isActive: model.activeStepID == step.id,
                        action: { model.begin(step, sourceFrame: rowFrames[step.id]) },
                        onFrameChange: { rowFrames[step.id] = $0 }
                    )
                }
            }

            footer
        }
        .padding(28)
        .frame(minWidth: 620, idealWidth: 680, maxWidth: 760)
        .onAppear {
            model.refresh()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set up permissions")
                .font(.system(size: 30, weight: .semibold, design: .rounded))

            Text("Guide users through macOS privacy settings with clear steps, live checks, and a floating helper that stays visible beside System Settings.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Image(systemName: model.isReady ? "checkmark.seal.fill" : "hand.raised.fill")
                .foregroundStyle(model.isReady ? .green : .secondary)

            Text(model.isReady ? "All required permissions are ready." : "The app should still ask before sensitive actions, even after permissions are granted.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Hide Guide") {
                model.hideCoach()
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 4)
    }
}

private struct PermissionStepRow: View {
    let step: PermissionStep
    let state: PermissionGrantState
    let isActive: Bool
    let action: () -> Void
    let onFrameChange: (NSRect) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            StatusGlyph(state: state, isActive: isActive)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(step.title)
                        .font(.system(size: 16, weight: .semibold))

                    if !step.isRequired {
                        Text("Optional")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.quaternary))
                    }
                }

                Text(step.reason)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.reassurance)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 18)

            VStack(alignment: .trailing, spacing: 7) {
                Button(buttonTitle) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .disabled(state == .checking || state == .openingSettings)

                Text(statusText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(state.isComplete ? .green : .secondary)
            }
            .frame(width: 190, alignment: .trailing)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isActive ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08), lineWidth: 1)
        )
        .background(ScreenFrameReader(onFrameChange: onFrameChange))
    }

    private var buttonTitle: String {
        state.isComplete ? "Open Again" : step.actionTitle
    }

    private var statusText: String {
        switch state {
        case .notStarted:
            "Not started"
        case .explaining:
            "Ready to start"
        case .openingSettings:
            "Opening settings"
        case .waitingForUser:
            "Waiting for approval"
        case .checking:
            "Checking"
        case .granted:
            "Ready"
        case .needsRestart:
            "Restart needed"
        case .failed:
            "Needs attention"
        }
    }
}

private struct ScreenFrameReader: NSViewRepresentable {
    let onFrameChange: (NSRect) -> Void

    func makeNSView(context: Context) -> FrameReportingView {
        FrameReportingView(onFrameChange: onFrameChange)
    }

    func updateNSView(_ nsView: FrameReportingView, context: Context) {
        nsView.onFrameChange = onFrameChange
        nsView.reportFrame()
    }
}

private final class FrameReportingView: NSView {
    var onFrameChange: (NSRect) -> Void

    init(onFrameChange: @escaping (NSRect) -> Void) {
        self.onFrameChange = onFrameChange
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reportFrame()
    }

    override func layout() {
        super.layout()
        reportFrame()
    }

    func reportFrame() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let window else { return }
            let frameInWindow = self.convert(self.bounds, to: nil)
            self.onFrameChange(window.convertToScreen(frameInWindow))
        }
    }
}

private struct StatusGlyph: View {
    let state: PermissionGrantState
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: 34, height: 34)

            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(foreground)
        }
    }

    private var fill: Color {
        if state.isComplete { return .green.opacity(0.18) }
        if isActive { return Color.accentColor.opacity(0.18) }
        return .secondary.opacity(0.12)
    }

    private var foreground: Color {
        if state.isComplete { return .green }
        if isActive { return .accentColor }
        return .secondary
    }

    private var symbol: String {
        switch state {
        case .granted:
            "checkmark"
        case .checking, .openingSettings:
            "arrow.triangle.2.circlepath"
        case .failed:
            "exclamationmark"
        case .needsRestart:
            "arrow.clockwise"
        default:
            "lock.open"
        }
    }
}
