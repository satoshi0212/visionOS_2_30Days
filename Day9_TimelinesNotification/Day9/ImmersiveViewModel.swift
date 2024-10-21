import RealityKit
import SwiftUI

class ImmersiveViewModel {

    var rootEntity: Entity

    func findTargetEntity(name: String) -> Entity? {
        rootEntity.children.first { $0.name == name }
    }

    init(rootEntity: Entity) {
        self.rootEntity = rootEntity
    }

    func removeAllCubes() {
        rootEntity.children.removeAll(where: { $0.name.hasPrefix("cube_") })
    }

    func addCube(name: String, position: SIMD3<Float>, color: UIColor) {
        let entity = ModelEntity(
            mesh: .generateBox(size: 0.2),
            materials: [UnlitMaterial(color: color)],
            collisionShape: .generateBox(size: SIMD3<Float>(repeating: 0.2)),
            mass: 0.0
        )

        entity.name = "cube_\(name)"
        entity.position = position
        entity.components.set(InputTargetComponent())
        entity.generateCollisionShapes(recursive: true)

        rootEntity.addChild(entity)
    }
}
