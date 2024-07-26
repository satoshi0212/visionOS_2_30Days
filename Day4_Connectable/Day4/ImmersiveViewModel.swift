import Foundation
import RealityKit
import RealityKitContent
import Observation

enum ConnectionPointType {
    case inPoint
    case outPoint
    case noPoint
}

@Observable
@MainActor
class ImmersiveViewModel {

    var rootEntity: Entity? = nil

    func findTargetEntity(name: String) -> Entity? {
        rootEntity?.children.first { $0.name == name }
    }

    init(rootEntity: Entity? = nil) {
        self.rootEntity = rootEntity
    }

    func setup() {
        Task {
            await addPiece(name: "A", position: [-0.5, 1.2, -1.5], color: .white)
            await addPiece(name: "B", position: [0.5, 1.2, -1.5], color: .gray)
            await addPiece(name: "C", position: [1.5, 1.2, -1.5], color: .blue)
        }
    }

    func addPiece(name: String, position: SIMD3<Float>, color: SimpleMaterial.Color) async {
        do {
            let scene = try await Entity(named: "ConnectableCube", in: realityKitContentBundle)
            let entity = scene.findEntity(named: "Cube")!
            entity.name = name
            entity.position = position
            entity.scale *= 2.0

            if let modelEntity = entity as? ModelEntity {
                let material = SimpleMaterial(color: color, isMetallic: false)
                modelEntity.model?.materials = [material]
            }

            let gestureComponent = GestureComponent.make(canDrag: true, preserveOrientationOnPivotDrag: true)
            entity.components.set(gestureComponent)

            var state = ConnectableStateComponent()
            state.inConnection = entity.descendants(containingSubstring: "connect_in").first
            state.outConnection = entity.descendants(containingSubstring: "connect_out").first
            state.entity = entity
            entity.connectableStateComponent = state
            entity.components.set(state)

            rootEntity?.addChild(entity)
        } catch {
            fatalError("\tEncountered fatal error: \(error.localizedDescription)")
        }
    }
}
