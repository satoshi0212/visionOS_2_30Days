import SwiftUI
import RealityKit

struct ImmersiveView: View {

    @Environment(HandTrackingModel.self) var handTrackingModel

    var body: some View {
        RealityView { content in
            handTrackingModel.setup()
        }
        .task {
            await handTrackingModel.startHandTracking()
        }
        .task {
            await handTrackingModel.processHandUpdated()
        }
    }
}
