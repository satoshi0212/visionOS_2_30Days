import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @Environment(AppModel.self) private var appModel

    private let brushWidthSelections: [Float] = [0.002, 0.005, 0.01, 0.03]

    var body: some View {

        @Bindable var appModel = appModel

        VStack(spacing: 40) {

            ToggleImmersiveSpaceButton()

            Divider()
            
            VStack {
                Text("Brush Width")
                Picker("Brush Width", selection: $appModel.brushSettigns.radius) {
                    ForEach(brushWidthSelections, id: \.self) { value in
                        Text(String(format: "%.3f", value))
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding()
        .frame(width: 480)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
