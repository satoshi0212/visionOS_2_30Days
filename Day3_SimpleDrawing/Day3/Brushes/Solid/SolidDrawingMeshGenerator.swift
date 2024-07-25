import RealityKit

final class SolidDrawingMeshGenerator {

    private var extruder: CurveExtruderWithEndcaps

    private let rootEntity: Entity

    var samples: [CurveSample] { extruder.samples }

    init(rootEntity: Entity, material: Material) {
        extruder = CurveExtruderWithEndcaps()
        self.rootEntity = rootEntity
        rootEntity.position = .zero
        rootEntity.components.set(SolidBrushComponent(generator: self, material: material))
    }

    @MainActor
    func update() throws -> LowLevelMesh? {
        try extruder.update()
    }

    func removeLast(sampleCount: Int) {
        extruder.removeLast(sampleCount: sampleCount)
    }

    func pushSamples(curve: [CurveSample]) {
        extruder.append(samples: curve)
    }

    func beginNewStroke() {
        extruder.beginNewStroke()
    }
}
