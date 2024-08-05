import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @Environment(AppModel.self) private var appModel
    @State private var viewModel = ImmersiveViewModel()

    var body: some View {
        RealityView { content in
            let entity = Entity()
            content.add(entity)
            viewModel.setup(entity: entity)
        }
        .onChange(of: appModel.mode) { (_, newValue) in
            viewModel.changeMode(mode: newValue)
        }
    }
}
