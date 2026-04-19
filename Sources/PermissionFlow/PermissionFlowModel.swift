import AppKit
import Combine
import Foundation

@MainActor
public final class PermissionFlowModel: ObservableObject {
    @Published public private(set) var steps: [PermissionStep]
    @Published public private(set) var states: [String: PermissionGrantState]
    @Published public private(set) var activeStepID: String?
    @Published public private(set) var isPolling = false

    private let coach: PermissionFloatingCoach
    private var pollingTask: Task<Void, Never>?

    public init(steps: [PermissionStep], coach: PermissionFloatingCoach = PermissionFloatingCoach()) {
        self.steps = steps
        self.states = Dictionary(uniqueKeysWithValues: steps.map { ($0.id, .notStarted) })
        self.activeStepID = steps.first?.id
        self.coach = coach
    }

    public var activeStep: PermissionStep? {
        guard let activeStepID else { return nil }
        return steps.first { $0.id == activeStepID }
    }

    public var isReady: Bool {
        steps
            .filter(\.isRequired)
            .allSatisfy { states[$0.id]?.isComplete == true }
    }

    public func state(for step: PermissionStep) -> PermissionGrantState {
        states[step.id, default: .notStarted]
    }

    public func begin(_ step: PermissionStep, sourceFrame: NSRect? = nil) {
        pollingTask?.cancel()
        activeStepID = step.id
        states[step.id] = .openingSettings

        lowerAppWindows()
        coach.show(for: step, sourceFrame: sourceFrame)

        pollingTask = Task { [weak self] in
            guard let self else { return }

            await step.openSettings()
            try? await Task.sleep(for: .milliseconds(250))
            self.coach.repositionNearSystemSettings()
            self.states[step.id] = .waitingForUser
            self.isPolling = true

            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(900))
                self.states[step.id] = .checking
                let status = await step.checkStatus()
                self.states[step.id] = status

                if status.isComplete {
                    self.coach.updateSuccess(for: step)
                    self.advance(after: step)
                    self.isPolling = false
                    return
                }
            }
        }
    }

    public func refresh() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            for step in self.steps {
                let status = await step.checkStatus()
                if status.isComplete {
                    self.states[step.id] = status
                }
            }
        }
    }

    public func hideCoach() {
        coach.close()
    }

    private func advance(after step: PermissionStep) {
        guard let index = steps.firstIndex(where: { $0.id == step.id }) else { return }
        let remaining = steps[(index + 1)...].first { states[$0.id]?.isComplete != true }
        activeStepID = remaining?.id
    }

    private func lowerAppWindows() {
        for window in NSApp.windows where !window.isKind(of: NSPanel.self) {
            window.orderBack(nil)
        }
    }
}
