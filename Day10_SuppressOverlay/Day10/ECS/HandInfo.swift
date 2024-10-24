import RealityKit
import SwiftUI

@Observable
class HandInfoParameters {
    var pitchRight: Float = 0 // radians
    var rollRight: Float = 0 // radians
    var yawRight: Float = 0 // radians

    var pitchLeft: Float = 0 // radians
    var rollLeft: Float = 0 // radians
    var yawLeft: Float = 0 // radians

    func reset() {
        pitchRight = 0
        rollRight = 0
        yawRight = 0
        pitchLeft = 0
        rollLeft = 0
        yawLeft = 0
    }
}

struct HandInfoComponent: Component {
    let parameters: HandInfoParameters
}

final class HandInfoSystem: System {

    static let query = EntityQuery(where: .has(HandInfoComponent.self))

    init(scene: RealityKit.Scene) {}

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let component = entity.components[HandInfoComponent.self] else { return }
            let parameters = component.parameters
            entity.components.set([
                PitchRollYawComponent(
                    pitchRight: parameters.pitchRight, rollRight: parameters.rollRight, yawRight: parameters.yawRight,
                    pitchLeft: parameters.pitchLeft, rollLeft: parameters.rollLeft, yawLeft: parameters.yawLeft
                )
            ])
        }
    }
}

struct PitchRollYawComponent: Component {
    var pitchRight: Float // radians
    var rollRight: Float  // radians
    var yawRight: Float  // radians
    var pitchLeft: Float // radians
    var rollLeft: Float  // radians
    var yawLeft: Float  // radians

    init(pitchRight: Float = .zero, rollRight: Float = .zero, yawRight: Float = .zero, pitchLeft: Float = .zero, rollLeft: Float = .zero, yawLeft: Float = .zero) {
        self.pitchRight = pitchRight
        self.rollRight = rollRight
        self.yawRight = yawRight
        self.pitchLeft = pitchLeft
        self.rollLeft = rollLeft
        self.yawLeft = yawLeft
    }
}
