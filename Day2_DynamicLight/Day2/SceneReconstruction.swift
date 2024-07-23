import RealityKit
import ARKit

@MainActor
final class SceneReconstruction {

    let entity = Entity()

    private let session = ARKitSession()
    private var provider = SceneReconstructionProvider()
    private var meshes: [UUID: Entity] = [:]

    func start() async throws {
        guard SceneReconstructionProvider.isSupported else { return }
        try await session.run([provider])
        prepareUpdates()
    }

    func stop() {
        session.stop()
        provider = SceneReconstructionProvider()

        for (key, mesh) in meshes {
            mesh.removeFromParent()
            meshes.removeValue(forKey: key)
        }
    }

    private func prepareUpdates() {
        Task { @MainActor in
            for await update in provider.anchorUpdates {
                let meshAnchor = update.anchor
                let shape = try await Task(priority: .background) {
                    try await ShapeResource.generateStaticMesh(from: meshAnchor)
                }.value

                switch update.event {
                case .added:
                    addMeshAnchor(meshAnchor, shape: shape)
                case .updated:
                    updateMeshAnchor(meshAnchor, shape: shape)
                case .removed:
                    removeMeshAnchor(meshAnchor)
                }
            }
        }
    }

    private func addMeshAnchor(_ meshAnchor: MeshAnchor, shape: ShapeResource) {
        let meshResource = MeshResource(shape: shape)
        var material = SimpleMaterial(color: .black.withAlphaComponent(0.3), isMetallic: true)
        material.triangleFillMode = .fill// .lines

        let entity = ModelEntity(mesh: meshResource, materials: [material])
        entity.name = "SceneReconstructionMesh-\(meshAnchor.id)"
        entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
        entity.components.set(PhysicsBodyComponent(mode: .static))

        configureCollisions(for: entity, with: shape)
        meshes[meshAnchor.id] = entity
        self.entity.addChild(entity)
    }

    private func updateMeshAnchor(_ meshAnchor: MeshAnchor, shape: ShapeResource) {
        guard let entity = self.meshes.removeValue(forKey: meshAnchor.id) else { return }
        entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
        configureCollisions(for: entity, with: shape)
        meshes[meshAnchor.id] = entity
    }

    private func removeMeshAnchor(_ meshAnchor: MeshAnchor) {
        meshes[meshAnchor.id]?.removeFromParent()
        meshes.removeValue(forKey: meshAnchor.id)
    }

    private func configureCollisions(for entity: Entity, with shape: ShapeResource) {
        entity.components.set(
            CollisionComponent(
                shapes: [shape],
                isStatic: true,
                filter: CollisionFilter(group: .sceneUnderstanding, mask: .all)
            )
        )
    }
}
