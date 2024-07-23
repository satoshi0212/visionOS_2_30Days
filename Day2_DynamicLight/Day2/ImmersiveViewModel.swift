import ARKit
import RealityKit
import RealityKitContent

@Observable
@MainActor
class ImmersiveViewModel {

    let rootEntity = Entity()
    private let sceneReconstruction = SceneReconstruction()

    func start() async throws {
        try await sceneReconstruction.start()
        rootEntity.addChild(sceneReconstruction.entity)
    }

    func stop() {
        for entity in rootEntity.children {
            entity.removeFromParent()
        }
        sceneReconstruction.entity.removeFromParent()
        sceneReconstruction.stop()
    }

    func addSphere() {
        let entity = ModelEntity()
        entity.components.set(ModelComponent(
            mesh: .generateSphere(radius: 0.06),
            materials: [SimpleMaterial(color: .yellow, isMetallic: true)]
        ))
        entity.position = SIMD3(x: 0.0, y: 1.5, z: -1.0)
        rootEntity.addChild(entity)

        entity.generateCollisionShapes(recursive: true)
        entity.components.set(InputTargetComponent())

        let gestureComponent = GestureComponent.make(canDrag: true, preserveOrientationOnPivotDrag: true)
        entity.components.set(gestureComponent)

        entity.components.set(PointLightComponent(color: .yellow, intensity: 10000.0))
    }
}
