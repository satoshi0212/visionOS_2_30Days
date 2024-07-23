import SwiftUI
import RealityKit

struct ContentView: View {

    @Environment(AppModel.self) private var appModel

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack {
            if !appModel.immersiveSpaceOpened {
                Button("Show Immersive Space") {
                    Task {
                        await openImmersiveSpace(id: "ImmersiveSpace")
                    }
                }
                .disabled(appModel.isTransitioning)
            } else {
                Button("Hide Immersive Space") {
                    Task {
                        appModel.immersiveSpaceOpened = false
                        await dismissImmersiveSpace()
                    }
                }
                .disabled(appModel.isTransitioning)
            }
        }
        .padding()
        .onChange(of: scenePhase, initial: true) {
            if scenePhase != .active {
                if appModel.immersiveSpaceOpened {
                    Task {
                        appModel.immersiveSpaceOpened = false
                        await dismissImmersiveSpace()
                    }
                }
            }
        }
    }
}
