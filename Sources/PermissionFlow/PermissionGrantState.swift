import Foundation

public enum PermissionGrantState: String, CaseIterable, Sendable {
    case notStarted
    case explaining
    case openingSettings
    case waitingForUser
    case checking
    case granted
    case needsRestart
    case failed

    public var isComplete: Bool {
        self == .granted
    }
}
