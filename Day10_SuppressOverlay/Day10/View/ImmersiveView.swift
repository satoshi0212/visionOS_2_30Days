import SwiftUI
import RealityKit

struct ImmersiveView: View {

    static let leftHandDisplayId: String = "LeftHandDisplay"
    static let rightHandDisplayId: String = "RightHandDisplay"

    @State private var pitchLeft: Float = .zero
    @State private var rollLeft: Float = .zero
    @State private var yawLeft: Float = .zero
    @State private var pitchRight: Float = .zero
    @State private var rollRight: Float = .zero
    @State private var yawRight: Float = .zero

    var body: some View {
        RealityView { content, attachments in

            let entity = Entity()
            entity.components.set(ModelComponent(
                mesh: .generateBox(width: 0.3, height: 0.03, depth: 0.1, splitFaces: false),
                materials: [UnlitMaterial(color: .red)])
            )
            entity.transform.rotation = simd_quatf(angle: .pi / 2, axis: simd_float3(1, 0, 0))  // Rotate to align the flat surface downward
            entity.position = SIMD3(x: 0.5, y: 1, z: -1.5)
            entity.components.set(HandInfoComponent(parameters: .init()))
            entity.components.set(
                ClosureComponent { _ in
                    if let localPitchRollYaw = entity.components[PitchRollYawComponent.self] {
                        pitchRight = localPitchRollYaw.pitchRight
                        rollRight = localPitchRollYaw.rollRight
                        yawRight = localPitchRollYaw.yawRight
                        let pitchQuat = simd_quatf(angle: pitchRight, axis: simd_float3(1, 0, 0))
                        let rollQuat = simd_quatf(angle: rollRight, axis: simd_float3(0, 0, 1))
                        let yawQuat = simd_quatf(angle: -yawRight, axis: simd_float3(0, 1, 0))
                        entity.transform.rotation = rollQuat * pitchQuat * yawQuat
                    }
                }
            )
            content.add(entity)

            let entityLeft = Entity()
            entityLeft.components.set(ModelComponent(
                mesh: .generateBox(width: 0.3, height: 0.03, depth: 0.1, splitFaces: false),
                materials: [UnlitMaterial(color: .green)])
            )
            entityLeft.transform.rotation = simd_quatf(angle: .pi / 2, axis: simd_float3(1, 0, 0))  // Rotate to align the flat surface downward
            entityLeft.position = SIMD3(x: -0.5, y: 1, z: -1.5)
            entityLeft.components.set(HandInfoComponent(parameters: .init()))
            entityLeft.components.set(
                ClosureComponent { _ in
                    if let localPitchRollYaw = entity.components[PitchRollYawComponent.self] {
                        pitchLeft = localPitchRollYaw.pitchLeft
                        rollLeft = localPitchRollYaw.rollLeft
                        yawLeft = localPitchRollYaw.yawLeft
                        let pitchQuat = simd_quatf(angle: pitchLeft, axis: simd_float3(1, 0, 0))
                        let rollQuat = simd_quatf(angle: rollLeft, axis: simd_float3(0, 0, 1))
                        let yawQuat = simd_quatf(angle: -yawLeft, axis: simd_float3(0, 1, 0))
                        entityLeft.transform.rotation = rollQuat * pitchQuat * yawQuat
                    }
                }
            )
            content.add(entityLeft)

            if let leftHandDisplay = attachments.entity(for: Self.leftHandDisplayId) {
                leftHandDisplay.name = Self.leftHandDisplayId
                leftHandDisplay.components.set(PitchRollYawLabelPlacementComponent())
                leftHandDisplay.components.set(BillboardComponent())
                content.add(leftHandDisplay)
            }

            if let rightHandDisplay = attachments.entity(for: Self.rightHandDisplayId) {
                rightHandDisplay.name = Self.rightHandDisplayId
                rightHandDisplay.components.set(PitchRollYawLabelPlacementComponent())
                rightHandDisplay.components.set(BillboardComponent())
                content.add(rightHandDisplay)
            }

            HandsInfoProviderSystem.registerSystem()
            content.add(Entity.makeHandTrackingEntities())

            HandInfoSystem.registerSystem()

        } attachments: {
            Attachment(id: Self.leftHandDisplayId) {
                VStack {
                    let pitchDisplay = Int(Angle(radians: Double(pitchLeft)).degrees)
                    let rollDisplay = Int(Angle(radians: Double(rollLeft)).degrees)
                    let yawDisplay = Int(Angle(radians: Double(yawLeft)).degrees)

                    Text("Pitch: \(pitchDisplay)º")
                    Text("Roll: \(rollDisplay)º")
                    Text("Yaw: \(yawDisplay)º")
                }
                .handsInfoLabelStyle()
            }

            Attachment(id: Self.rightHandDisplayId) {
                VStack {
                    let pitchDisplay = Int(Angle(radians: Double(pitchRight)).degrees)
                    let rollDisplay = Int(Angle(radians: Double(rollRight)).degrees)
                    let yawDisplay = Int(Angle(radians: Double(yawRight)).degrees)

                    Text("Pitch: \(pitchDisplay)º")
                    Text("Roll: \(rollDisplay)º")
                    Text("Yaw: \(yawDisplay)º")
                }
                .handsInfoLabelStyle()
            }
        }
        .persistentSystemOverlays(.hidden)
    }
}

struct HandsInfoLabelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.title)
            .monospacedDigit()
    }
}

extension View {
    func handsInfoLabelStyle() -> some View {
        modifier(HandsInfoLabelModifier())
    }
}
