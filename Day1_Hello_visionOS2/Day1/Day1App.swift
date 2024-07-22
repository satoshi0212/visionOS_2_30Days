import SwiftUI
import RealityKit

@main
struct Day1: App {

    @State private var appModel = AppModel()

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some SwiftUI.Scene {
        Group {
            WindowGroup {
                ContentView()
                    .environment(appModel)
                    .fixedSize()
            }
            .windowResizability(.contentSize)

            ImmersiveSpace(id: "ImmersiveSpace") {
                ImmersiveView()
                    .environment(appModel)
            }
            .immersionStyle(selection: .constant(.mixed), in: .mixed)
        }
        .onChange(of: appModel.wantsToPresentImmersiveSpace) {
            appModel.isPresentingImmersiveSpace = true
        }
        .onChange(of: appModel.isPresentingImmersiveSpace) {
            Task {
                if appModel.isPresentingImmersiveSpace {
                    switch await openImmersiveSpace(id: "ImmersiveSpace") {
                    case .opened:
                        appModel.isPresentingImmersiveSpace = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        appModel.isPresentingImmersiveSpace = false
                    }
                } else {
                    await dismissImmersiveSpace()
                }
            }
        }
    }
}
