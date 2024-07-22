import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @Environment(AppModel.self) private var appModel
    @State private var viewModel = ImmersiveViewModel()

    var body: some View {
        RealityView { content in
            content.add(viewModel.rootEntity)

            Task {
                await viewModel.setupRootEntity()
                appModel.phase = .playing // change state after setup complete to play animation
            }
        }
        .onChange(of: appModel.phase) {
            if appModel.phase == .playing {
                viewModel.playAnimation()
            }
        }
        .onChange(of: appModel.wantsToPresentImmersiveSpace) {
            if appModel.wantsToPresentImmersiveSpace {
                appModel.isPresentingImmersiveSpace = true
            } else {
                appModel.isPresentingImmersiveSpace = false
                appModel.phase = .waitingToStart
            }
        }
    }
}
