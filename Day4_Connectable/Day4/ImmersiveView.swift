import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {

    static let connectableQuery = EntityQuery(where: .has(ConnectableComponent.self))

    @Environment(AppModel.self) private var appModel

    @State private var viewModel = ImmersiveViewModel()
    @State var isSnapping = false

    let maximumSnapDistance = Float(0.14)
    let secondsAfterDragToContinueSnap = TimeInterval(0.025)
    let snapEpsilon = 0.000_000_1

    var body: some View {
        RealityView { content in
            let entity = Entity()
            viewModel.rootEntity = entity
            content.add(entity)
            viewModel.setup()
        }
        .installGestures(dragCompletion: { value in
            let targetEntity = value.entity
            if let entity = targetEntity.connectableAncestor {
                handleSnap(entity)
            }
        })
        .task {
            SoundEffectPlayer.shared.stopAll()
        }
    }

    /// This function performs a linear interpolation on a provided `Float` value based on a start, end, and progress value. It applies
    /// a quartic  calculation to the result, which causes snapping to accelerate as it gets closer to the snap point. This gives a more
    /// natural feel, much like a magnet accelerating toward the opposite pole of another magnet.
    func quarticLerp(_ start: Float, _ end: Float, _ alpha: Float) -> Float {
        let alpha = min(max(alpha * alpha * alpha * alpha, 0), 1)
        return start * (1.0 - alpha) + end * alpha
    }

    /// This function performs a linear interpolation on a provided `SIMD3<Float>` value based on a start, end, and progress value. It applies
    /// a quartic calculation to the result, which causes snapping to accelerate as it gets closer to the snap point. This gives a more
    /// natural feel, much like a magnet accelerating toward the opposite pole of another magnet.
    func quarticLerp(_ start: SIMD3<Float>, _ end: SIMD3<Float>, _ alpha: Float) -> SIMD3<Float> {
        let x = quarticLerp(start.x, end.x, alpha)
        let y = quarticLerp(start.y, end.y, alpha)
        let z = quarticLerp(start.z, end.z, alpha)
        return SIMD3<Float>(x: x, y: y, z: z)
    }
}
