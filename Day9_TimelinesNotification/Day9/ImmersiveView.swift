import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    @State private var viewModel: ImmersiveViewModel = .init(rootEntity: Entity())
    private let notificationTrigger = NotificationCenter.default.publisher(for: Notification.Name("RealityKit.NotificationTrigger"))

    var body: some View {
        RealityView { content in
            content.add(viewModel.rootEntity)
            if let immersiveContentEntity = try? await Entity(named: "Timelines", in: realityKitContentBundle) {
                viewModel.rootEntity.addChild(immersiveContentEntity)
            }
        }
        .gesture(TapGesture().targetedToAnyEntity()
            .onEnded({ value in
                _ = value.entity.applyTapForBehaviors()
            })
        )
        .onReceive(notificationTrigger) { output in
            guard let entity = output.userInfo?["RealityKit.NotificationTrigger.SourceEntity"] as? Entity,
                  let notificationName = output.userInfo?["RealityKit.NotificationTrigger.Identifier"] as? String
            else { return }

            print(entity.name, notificationName)

            switch notificationName {
            case .notification0:
                viewModel.removeAllCubes()
            case .notification1:
                viewModel.addCube(name: notificationName, position: [-0.6, 1.8, -1.5], color: .init(white: 0.9, alpha: 1.0))
            case .notification2:
                viewModel.addCube(name: notificationName, position: [-0.3, 1.8, -1.5], color: .init(white: 0.7, alpha: 1.0))
            case .notification3:
                viewModel.addCube(name: notificationName, position: [0.0, 1.8, -1.5], color: .init(white: 0.5, alpha: 1.0))
            case .notification4:
                viewModel.addCube(name: notificationName, position: [0.3, 1.8, -1.5], color: .init(white: 0.3, alpha: 1.0))
            case .notification5:
                viewModel.addCube(name: notificationName, position: [0.6, 1.8, -1.5], color: .init(white: 0.1, alpha: 1.0))
            default:
                break
            }
        }
    }
}

private extension String {
    static let notification0 = "NotificationAction_0"
    static let notification1 = "NotificationAction_1"
    static let notification2 = "NotificationAction_2"
    static let notification3 = "NotificationAction_3"
    static let notification4 = "NotificationAction_4"
    static let notification5 = "NotificationAction_5"
}
