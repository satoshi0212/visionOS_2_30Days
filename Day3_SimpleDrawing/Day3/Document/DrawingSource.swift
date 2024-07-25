import Algorithms
import Collections
import Foundation
import RealityKit

private extension Collection where Element: FloatingPoint {

    /// Computes the average over this collection, omitting a number of the largest and smallest values.
    ///
    /// - Parameter truncation: The number or largest and smallest values to omit.
    /// - Returns: The mean value of the collection, after the truncated values are omitted.
    func truncatedMean(truncation: Int) -> Element {
        guard !isEmpty else { return .zero }

        var sortedSelf = Deque(sorted())
        let truncationLimit = (count - 1) / 2
        sortedSelf.removeFirst(Swift.min(truncationLimit, truncation))
        sortedSelf.removeLast(Swift.min(truncationLimit, truncation))
        return sortedSelf.reduce(Element.zero) { $0 + $1 } / Element(sortedSelf.count)
    }
}

public struct DrawingSource {

    private let brushSettings: BrushSettings
    private let rootEntity: Entity
    private var solidMaterial: RealityKit.Material

    private var solidMeshGenerator: SolidDrawingMeshGenerator
    private var smoothCurveSampler: SmoothCurveSampler

    private var inputsOverTime: Deque<(SIMD3<Float>, TimeInterval)> = []

    private mutating func trace(position: SIMD3<Float>, speed: Float) {
        let point = SolidBrushCurvePoint(position: position,
                                         radius: brushSettings.radius,
                                         color: brushSettings.color,
                                         roughness: 0.5,
                                         metallic: 0.0)
        smoothCurveSampler.trace(point: point)

    }

    @MainActor
    init(brushSettins: BrushSettings, rootEntity: Entity, solidMaterial: Material? = nil, sparkleMaterial: Material? = nil) async {
        self.brushSettings = brushSettins
        self.rootEntity = rootEntity

        let solidMeshEntity = Entity()
        rootEntity.addChild(solidMeshEntity)
        self.solidMaterial = solidMaterial ?? SimpleMaterial()
        solidMeshGenerator = SolidDrawingMeshGenerator(rootEntity: solidMeshEntity, material: self.solidMaterial)
        smoothCurveSampler = SmoothCurveSampler(flatness: 0.001, generator: self.solidMeshGenerator)
    }

    @MainActor
    mutating func receive(input: InputData?, time: TimeInterval) {
        while let (_, headTime) = inputsOverTime.first, time - headTime > 0.1 {
            inputsOverTime.removeFirst()
        }

        if let brushTip = input?.brushTip {
            let lastInputPosition = inputsOverTime.last?.0
            inputsOverTime.append((brushTip, time))

            if let lastInputPosition, lastInputPosition == brushTip {
                return
            }
        }

        let speedsOverTime = inputsOverTime.adjacentPairs().map { input0, input1 in
            let (point0, time0) = input0
            let (point1, time1) = input1
            let distance = distance(point0, point1)
            let time = abs(time0 - time1)
            return distance / Float(time)
        }

        let smoothSpeed = speedsOverTime.truncatedMean(truncation: 2)

        if let input, input.isDrawing {
            trace(position: input.brushTip, speed: smoothSpeed)
        } else {
            if !smoothCurveSampler.isEmpty {
                inputsOverTime.removeAll()
                smoothCurveSampler.beginNewStroke()
            }
        }
    }
}
