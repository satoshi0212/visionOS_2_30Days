import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @Environment(ViewModel.self) private var viewModel

    var body: some View {
        RealityView { content in
            let entity = Entity()
            content.add(entity)
            await viewModel.setup(rootEntity: entity)
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded({ value in
            viewModel.replay()
        }))
        .onChange(of: viewModel.hueRange, { _, newValue in
            viewModel.onChange(hue: newValue, saturate: nil, value: nil)
        })
        .onChange(of: viewModel.saturateRange, { _, newValue in
            viewModel.onChange(hue: nil, saturate: newValue, value: nil)
        })
        .onChange(of: viewModel.valueRange, { _, newValue in
            viewModel.onChange(hue: nil, saturate: nil, value: newValue)
        })
        .onDisappear {
            viewModel.exit()
        }
    }
}
