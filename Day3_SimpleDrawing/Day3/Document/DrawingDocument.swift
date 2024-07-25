import Collections
import RealityKit
import RealityKitContent
import SwiftUI

public enum Chirality: Equatable {
    case left, right
}

struct InputData {

    var thumbTip: SIMD3<Float>
    var indexFingerTip: SIMD3<Float>

    var brushTip: SIMD3<Float> {
        return (thumbTip + indexFingerTip) / 2
    }

    var isDrawing: Bool {
        return distance(thumbTip, indexFingerTip) < 0.015
    }
}

class DrawingDocument {

    private let rootEntity: Entity
    private var rightSource: DrawingSource
    private var startDate: Date

    @MainActor
    init(brushSettings: BrushSettings, rootEntity: Entity) async {
        self.rootEntity = rootEntity
        self.startDate = .now

        let rightRootEntity = Entity()
        rootEntity.addChild(rightRootEntity)

        var solidMaterial: RealityKit.Material = SimpleMaterial()
        if let material = try? await ShaderGraphMaterial(named: "/Root/Material", from: "SolidBrushMaterial", in: realityKitContentBundle) {
            solidMaterial = material
        }

        rightSource = await DrawingSource(brushSettins: brushSettings, rootEntity: rightRootEntity, solidMaterial: solidMaterial)
    }

    @MainActor
    func receive(input: InputData?, chirality: Chirality) {
        switch chirality {
        case .left:
            // only the right hand is used this time
            break
        case .right:
            rightSource.receive(input: input, time: startDate.distance(to: .now))
        }
    }
}
