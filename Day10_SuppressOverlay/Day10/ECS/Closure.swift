import Foundation
import RealityKit

struct ClosureComponent: Component {
    let closure: (TimeInterval) -> Void

    init(closure: @escaping (TimeInterval) -> Void) {
        self.closure = closure

        ClosureSystem.registerSystem()
    }
}

final class ClosureSystem: System {
    static let query = EntityQuery(where: .has(ClosureComponent.self))

    public init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let comp = entity.components[ClosureComponent.self] else { continue }
            comp.closure(context.deltaTime)
        }
    }
}
