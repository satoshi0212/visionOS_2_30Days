import RealityKit
import Foundation

public struct HandComponent: Component {
    var chirality: Chirality
    var provider: AnchorEntityInputProvider

    var thumbTip: AnchorEntity
    var indexFingerTip: AnchorEntity

    var currentData: InputData? {
        let thumbTipPosition = thumbTip.position(relativeTo: nil)
        let indexFingerTipPosition = indexFingerTip.position(relativeTo: nil)

        if length(thumbTipPosition) < 0.0001 || length(indexFingerTipPosition) < 0.0001 {
            return nil
        } else {
            return InputData(thumbTip: thumbTipPosition, indexFingerTip: indexFingerTipPosition)
        }
    }
}

final class AnchorEntityInputProvider {
    public var document: DrawingDocument

    private var rootEntity: Entity

    private var leftEntity = Entity()
    private var rightEntity = Entity()

    private let session: SpatialTrackingSession

    @MainActor
    init(rootEntity: Entity, document: DrawingDocument) async {
        self.rootEntity = rootEntity
        self.document = document
        session = SpatialTrackingSession()

        let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
        _ = await session.run(configuration)

        HandComponent.registerComponent()
        DrawingSystem.registerSystem()

        let leftIndexFinger = AnchorEntity(.hand(.left, location: .indexFingerTip))
        let leftThumb = AnchorEntity(.hand(.left, location: .thumbTip))
        let rightIndexFinger = AnchorEntity(.hand(.right, location: .indexFingerTip))
        let rightThumb = AnchorEntity(.hand(.right, location: .thumbTip))

        leftEntity.components.set(HandComponent(chirality: .left, provider: self, thumbTip: leftThumb, indexFingerTip: leftIndexFinger))
        rootEntity.addChild(leftIndexFinger)
        rootEntity.addChild(leftThumb)
        rootEntity.addChild(leftEntity)

        rightEntity.components.set(HandComponent(chirality: .right, provider: self, thumbTip: rightThumb, indexFingerTip: rightIndexFinger))
        rootEntity.addChild(rightIndexFinger)
        rootEntity.addChild(rightThumb)
        rootEntity.addChild(rightEntity)
    }

    deinit {
        Task {
            print("■ stop called.")
            await session.stop()
        }
    }
}

private class DrawingSystem: System {
    private static let handQuery = EntityQuery(where: .has(HandComponent.self))

    required init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.handQuery, updatingSystemWhen: .rendering) {
            let handComponent = entity.components[HandComponent.self]!
            let provider = handComponent.provider
            provider.document.receive(input: handComponent.currentData, chirality: handComponent.chirality)
        }
    }
}
