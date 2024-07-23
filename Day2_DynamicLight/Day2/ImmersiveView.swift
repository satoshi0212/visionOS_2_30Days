import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    @Environment(AppModel.self) private var appModel
    @State private var viewModel = ImmersiveViewModel()

    var body: some View {
        RealityView { content in
            content.add(viewModel.rootEntity)
            viewModel.addSphere()
            appModel.immersiveSpaceOpened = true
        }
        .installGestures()
        .onChange(of: appModel.immersiveSpaceOpened, initial: false) { old, new in
            if old == new { return }
            Task {
                appModel.isTransitioning = true
                if new {
                    try await viewModel.start()
                } else {
                    viewModel.stop()
                }
                appModel.isTransitioning = false
            }
        }
    }
}
