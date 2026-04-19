import Foundation

public struct PermissionStep: Identifiable, Sendable {
    public typealias Action = @MainActor @Sendable () async -> Void
    public typealias Check = @MainActor @Sendable () async -> PermissionGrantState

    public let id: String
    public let title: String
    public let shortTitle: String
    public let reason: String
    public let reassurance: String
    public let actionTitle: String
    public let waitingTitle: String
    public let waitingDetail: String
    public let successTitle: String
    public let troubleshooting: String
    public let guideSteps: [String]
    public let guideFootnote: String
    public let allowsAppIconDrag: Bool
    public let isRequired: Bool
    public let openSettings: Action
    public let checkStatus: Check

    public init(
        id: String,
        title: String,
        shortTitle: String,
        reason: String,
        reassurance: String,
        actionTitle: String,
        waitingTitle: String,
        waitingDetail: String,
        successTitle: String,
        troubleshooting: String,
        guideSteps: [String] = [],
        guideFootnote: String = "You can close this guide and reopen it from the app.",
        allowsAppIconDrag: Bool = true,
        isRequired: Bool = true,
        openSettings: @escaping Action,
        checkStatus: @escaping Check
    ) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.reason = reason
        self.reassurance = reassurance
        self.actionTitle = actionTitle
        self.waitingTitle = waitingTitle
        self.waitingDetail = waitingDetail
        self.successTitle = successTitle
        self.troubleshooting = troubleshooting
        self.guideSteps = guideSteps
        self.guideFootnote = guideFootnote
        self.allowsAppIconDrag = allowsAppIconDrag
        self.isRequired = isRequired
        self.openSettings = openSettings
        self.checkStatus = checkStatus
    }
}
