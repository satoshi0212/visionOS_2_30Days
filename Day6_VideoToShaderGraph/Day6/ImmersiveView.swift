import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @Environment(ViewModel.self) private var viewModel

    var body: some View {
        RealityView { content in
            let entity = Entity()
            content.add(entity)
            viewModel.rootEntity = entity
            Task {
                await viewModel.setup()
            }
        }
        .onDisappear {
            viewModel.exit()
        }
    }
}
