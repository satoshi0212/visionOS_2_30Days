import SwiftUI
import RealityKit

struct ContentView: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {

        @Bindable var appModel = appModel

        VStack {
            Toggle(
                appModel.wantsToPresentImmersiveSpace ? "Return" : "Enter",
                isOn: $appModel.wantsToPresentImmersiveSpace
            )
            .font(.title)
            .toggleStyle(ToggleImmersiveSpaceButtonStyle())
            .buttonBorderShape(.roundedRectangle(radius: 36))
            .disabled(toggleIsDisabled)
        }
        .padding()
        .frame(width: 300)
    }
    
    var toggleIsDisabled: Bool {
        (!appModel.wantsToPresentImmersiveSpace && appModel.isPresentingImmersiveSpace)
    }
}

struct ToggleImmersiveSpaceButtonStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
                .frame(maxWidth: .infinity, idealHeight: 80)
        }
    }
}
