import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @Environment(ViewModel.self) var viewModel

    var body: some View {
        RealityView { content in
            content.add(viewModel.setupContentEntity())
            viewModel.makePolygon()
        }
    }
}
