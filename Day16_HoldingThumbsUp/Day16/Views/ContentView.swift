import SwiftUI
import RealityKit

struct ContentView: View {

    @Environment(AppModel.self) var appModel
    @Environment(HandTrackingModel.self) var handTrackingModel

    var body: some View {
        VStack(spacing: 40) {
            if appModel.immersiveSpaceState == .open {
                Text(handTrackingModel.handGesture.rawValue)
                    .font(.largeTitle)

                ThumbsUpProgressView(handTrackingModel: handTrackingModel)
            }

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}
