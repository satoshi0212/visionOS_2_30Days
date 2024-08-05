import SwiftUI
import RealityKit

private enum VisibilityState: String, CaseIterable, Identifiable {
    case visibleState, hiddenState, automaticState
    var id: Self { self }
    var state: Visibility {
        switch self {
        case .visibleState:
            return .visible
        case .hiddenState:
            return .hidden
        case .automaticState:
            return .automatic
        }
    }
}

struct ContentView: View {

    @Environment(AppModel.self) private var appModel

    @State private var selectedLVState: VisibilityState = .visibleState

    var body: some View {

        @Bindable var appModel = appModel

        VStack(spacing: 40) {
            ToggleImmersiveSpaceButton()
            
            if appModel.immersiveSpaceState == .open {

                Divider()

                VStack {
                    HStack {
                        Text("Upper Limbs")
                        Picker("Upper Limb Visibility", selection: $selectedLVState) {
                            Text("Visible").tag(VisibilityState.visibleState)
                            Text("Hidden").tag(VisibilityState.hiddenState)
                            Text("Automatic").tag(VisibilityState.automaticState)
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack {
                        Text("Mode")
                        Picker("Mode", selection: $appModel.mode) {
                            ForEach(AppModel.Mode.allCases, id: \.self) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
        .padding()
        .frame(width: 480)
        .onChange(of: selectedLVState) { _, newState in
            appModel.upperLimbVisibility = newState.state
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
