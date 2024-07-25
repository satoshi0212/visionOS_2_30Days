import RealityKit

struct SolidBrushComponent: Component {
    var generator: SolidDrawingMeshGenerator
    var material: RealityKit.Material
}

class SolidBrushSystem: System {
    private static let query = EntityQuery(where: .has(SolidBrushComponent.self))

    required init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            let brushComponent: SolidBrushComponent = entity.components[SolidBrushComponent.self]!

            // Call `update` on the generator.
            // This returns a non-nil `LowLevelMesh` if a new mesh had to be allocated.
            // This can happen when the number of samples exceeds the capacity of the mesh.
            //
            // If the generator returns a new `LowLevelMesh`,
            // apply it to the entity's `ModelComponent`.
            if let newMesh = try? brushComponent.generator.update(),
               let resource = try? MeshResource(from: newMesh) {
                if entity.components.has(ModelComponent.self) {
                    entity.components[ModelComponent.self]!.mesh = resource
                } else {
                    let modelComponent = ModelComponent(mesh: resource, materials: [brushComponent.material])
                    entity.components.set(modelComponent)
                }
            }
        }
    }
}
