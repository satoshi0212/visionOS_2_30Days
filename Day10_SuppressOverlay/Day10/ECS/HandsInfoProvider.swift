import Foundation
import RealityKit

struct HandTrackingComponent: Component {
    enum Location: String {
        case leftPalm, rightPalm
    }

    let location: HandTrackingComponent.Location
}

struct PitchRollYawLabelPlacementComponent: Component {
    init() {
        PitchRollYawLabelPlacementComponent.registerComponent()
    }

    func computeTransformWith(palmTransform: float4x4) -> float4x4 {
        let offset = SIMD3<Float>(0, 0.12, 0)
        let position = palmTransform.translation + offset
        return float4x4(translation: position)
    }
}

final class HandsInfoProviderSystem: System {

    static let pitchRollYawLabelQuery = EntityQuery(where: .has(PitchRollYawLabelPlacementComponent.self))

    let session = SpatialTrackingSession()

    init(scene: Scene) {
        HandTrackingComponent.registerComponent()

        Task { @MainActor in
            let config = SpatialTrackingSession.Configuration(tracking: [.hand])
            _ = await session.run(config)
        }
    }

    func update(context: SceneUpdateContext) {
        var transforms: [HandTrackingComponent.Location: simd_float4x4] = [:]

        for entity in context.entities(matching: EntityQuery(where: .has(HandTrackingComponent.self)), updatingSystemWhen: .rendering) {
            guard let anchorEntity = entity as? AnchorEntity,
                  anchorEntity.isAnchored else {
                continue
            }
            guard let handTrackingComponent = entity.components[HandTrackingComponent.self] else { continue }
            transforms[handTrackingComponent.location] = entity.transformMatrix(relativeTo: nil)
        }

        for entity in context.entities(matching: HandsInfoProviderSystem.pitchRollYawLabelQuery, updatingSystemWhen: .rendering) {
            guard let component = entity.components[PitchRollYawLabelPlacementComponent.self] else { continue }
            let transform: float4x4? = {
                if entity.name == ImmersiveView.leftHandDisplayId, let leftPalmTransform = transforms[.leftPalm] {
                    return component.computeTransformWith(palmTransform: leftPalmTransform)
                } else if entity.name == ImmersiveView.rightHandDisplayId, let rightPalmTransform = transforms[.rightPalm] {
                    return component.computeTransformWith(palmTransform: rightPalmTransform)
                }
                return nil
            }()
            guard let transform else { continue }
            entity.interpolate(towards: transform, smoothingFactor: 0.1)
        }

        for entity in context.entities(matching: EntityQuery(where: .has(HandInfoComponent.self)), updatingSystemWhen: .rendering) {
            updateHandInfoParameters(for: entity, context: context, transforms: transforms)
        }
    }

    private func updateHandInfoParameters(for entity: Entity, context: SceneUpdateContext, transforms: [HandTrackingComponent.Location: simd_float4x4]) {
        guard let leftPalmTransform = transforms[.leftPalm] else { return }
        guard let rightPalmTransform = transforms[.rightPalm] else { return }

        let parameters = entity.components[HandInfoComponent.self]!.parameters

        let (pitchRight, rollRight, yawRight) = computePitchRollYaw(from: rightPalmTransform)
        parameters.pitchRight = pitchRight
        parameters.rollRight = rollRight
        parameters.yawRight = yawRight

        let leftHandAdjustedTransform = adjustForLeftHand(palmTransform: leftPalmTransform)
        let (pitchLeft, rollLeft, yawLeft) = computePitchRollYaw(from: leftHandAdjustedTransform)
        parameters.pitchLeft = pitchLeft
        parameters.rollLeft = rollLeft
        parameters.yawLeft = yawLeft
    }

    private func adjustForLeftHand(palmTransform: float4x4) -> float4x4 {
        let mirrorYZ = float4x4(columns: (
            SIMD4<Float>(-1, 0, 0, 0),
            SIMD4<Float>(0, -1, 0, 0),
            SIMD4<Float>(0, 0, -1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
        return mirrorYZ * palmTransform
    }

    private func computePitchRollYaw(from rightPalmTransform: float4x4) -> (Float, Float, Float) {
        // rightPalmTransform definition:
        // [1, 0, 0] is the direction from palm to wrist
        // [0, 1, 0] is the direction from palm to center of hand
        // [0, 0, 1] is the direction from palm to the opposite of thumb
        //
        // Define `handForward` as the direction from wrist to palm,
        // and `handThumb` as the direction from palm to thumb.
        let palmToWrist: SIMD4<Float> = [-1, 0, 0, 0]
        let palmToThumb: SIMD4<Float> = [0, 0, -1, 0]

        let handForward = (rightPalmTransform * palmToWrist).xyz
        let handForwardNormalized = normalizeIfNonZero(handForward)

        let handThumb = (rightPalmTransform * palmToThumb).xyz
        let handThumbNormalized = normalizeIfNonZero(handThumb)

        let projectToPitchPlane: SIMD3 = normalizeIfNonZero(SIMD3(0, handForwardNormalized.y, handForwardNormalized.z))
        let angleFromZ: Float = atan2(projectToPitchPlane.y, projectToPitchPlane.z)
        let pitch: Float = angleFromZ.isNaN ? 0 : -angleFromZ + .pi * sign(angleFromZ)

        let projectToRollPlane: SIMD3 = normalizeIfNonZero(SIMD3(handThumbNormalized.x, handThumbNormalized.y, 0))
        let angleFromX: Float = atan2(projectToRollPlane.y, projectToRollPlane.x)
        let roll: Float = angleFromX.isNaN ? 0 : angleFromX - .pi * sign(angleFromX)

        let projectToYawPlane: SIMD3 = normalizeIfNonZero(SIMD3(handForwardNormalized.x, 0, handForwardNormalized.z))
        let angleFromXForYaw: Float = atan2(projectToYawPlane.z, projectToYawPlane.x)
        let yaw: Float = angleFromXForYaw.isNaN ? 0 : angleFromXForYaw - .pi * sign(angleFromXForYaw)

        return (pitch, roll, yaw)
    }

    private func normalizeIfNonZero(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        return simd_length(vector) > 0 ? normalize(vector) : vector
    }
}

extension Entity {
    func interpolate(towards: float4x4, smoothingFactor: Float) {
        let current = transformMatrix(relativeTo: nil)
        setTransformMatrix(current + (towards - current) * smoothingFactor, relativeTo: nil)
    }

    static func makeHandTrackingEntities() -> Entity {
        let container = Entity()
        container.name = "HandTrackingEntitiesContainer"

        let leftHand = AnchorEntity(.hand(.left, location: .palm))
        leftHand.components.set(HandTrackingComponent(location: .leftPalm))

        let rightHand = AnchorEntity(.hand(.right, location: .palm))
        rightHand.components.set(HandTrackingComponent(location: .rightPalm))

        container.addChild(leftHand)
        container.addChild(rightHand)

        return container
    }
}
