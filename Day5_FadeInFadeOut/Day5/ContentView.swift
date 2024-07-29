import SwiftUI
import RealityKit

struct ContentView: View {

    @Environment(AppModel.self) private var appModel
    @Environment(ViewModel.self) private var viewModel

    var body: some View {
        
        @Bindable var viewModel = viewModel

        ZStack {
            VStack(spacing: 20) {
                let colorBinding = Color.makeBinding(from: $viewModel.skyboxColor)
                ColorPicker("Color", selection: colorBinding)

                Divider()

                Button("Fade in") {
                    viewModel.fadeIn(animated: true, duration: 4.0)
                }

                Button("Fade out") {
                    viewModel.fadeOut(animated: true, duration: 1.0)
                }

                Divider()

                ToggleImmersiveSpaceButton()
            }
            .padding()
            .opacity(appModel.immersiveSpaceState == .open ? 1 : 0)
            .padding()

            VStack {
                ToggleImmersiveSpaceButton()
            }
            .padding()
            .opacity(appModel.immersiveSpaceState == .open ? 0 : 1)
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
        .environment(ViewModel())
}
