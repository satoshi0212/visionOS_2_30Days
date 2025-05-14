import SwiftUI

@main
struct Day16App: App {

    @State private var appModel = AppModel()
    @State private var handTrackingModel = HandTrackingModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .environment(handTrackingModel)
        }
        .defaultSize(width: 800, height: 600)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .environment(handTrackingModel)
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
