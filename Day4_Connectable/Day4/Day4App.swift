import SwiftUI
import RealityKitContent

@main
struct Day4App: App {

    @State private var appModel = AppModel()

    init() {
        RealityKitContent.GestureComponent.registerComponent()
        RealityKitContent.ConnectableComponent.registerComponent()
        RealityKitContent.ConnectableStateComponent.registerComponent()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
