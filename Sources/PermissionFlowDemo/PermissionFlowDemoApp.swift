import PermissionFlow
import SwiftUI

@main
struct PermissionFlowDemoApp: App {
    @StateObject private var model = PermissionFlowModel(
        steps: [
            MacPermission.screenRecording(),
            MacPermission.accessibility(),
            MacPermission.automation(),
            MacPermission.fullDiskAccess()
        ]
    )

    var body: some Scene {
        WindowGroup {
            PermissionFlowView(model: model)
        }
        .windowStyle(.titleBar)
    }
}
