import SwiftUI
import RealityKitContent

@main
struct Day2App: App {

    @State private var appModel = AppModel()

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

    init() {
        RealityKitContent.GestureComponent.registerComponent()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(appModel)
        }
        .onChange(of: scenePhase, initial: true) {
            if scenePhase != .active {
                if appModel.immersiveSpaceOpened {
                    Task {
                        await dismissImmersiveSpace()
                        appModel.immersiveSpaceOpened = false
                    }
                }
            }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
