import SwiftUI
import RealityKit

struct ContentView: View {

    @Environment(ViewModel.self) private var viewModel

    var body: some View {

        @Bindable var viewModel = viewModel

        VStack {
            HStack {
                Text("Hue")
                Slider (value: $viewModel.hueRange, in: 0.0...0.2, step: 0.02)
            }
            .padding(.horizontal)

            HStack {
                Text("Saturate")
                Slider (value: $viewModel.saturateRange, in: 0.0...1.0, step: 0.1)
            }
            .padding(.horizontal)

            HStack {
                Text("Value")
                Slider (value: $viewModel.valueRange, in: 0.0...1.0, step: 0.1)
            }
            .padding(.horizontal)

            Divider()

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}
