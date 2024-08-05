import SwiftUI
import RealityKit
import Observation

@Observable
class ImmersiveViewModel {

    private static let handJoints: Array<AnchoringComponent.Target.HandLocation.HandJoint> = [
        .wrist,
        .thumbTip,
        .indexFingerTip,
        .thumbKnuckle,
        .thumbIntermediateBase,
        .thumbIntermediateTip,
        .indexFingerMetacarpal,
        .indexFingerKnuckle,
        .indexFingerIntermediateBase,
        .indexFingerIntermediateTip,
        .middleFingerMetacarpal,
        .middleFingerKnuckle,
        .middleFingerIntermediateBase,
        .middleFingerIntermediateTip,
        .middleFingerTip,
        .ringFingerMetacarpal,
        .ringFingerKnuckle,
        .ringFingerIntermediateBase,
        .ringFingerIntermediateTip,
        .ringFingerTip,
        .littleFingerMetacarpal,
        .littleFingerKnuckle,
        .littleFingerIntermediateBase,
        .littleFingerIntermediateTip,
        .littleFingerTip,
        .forearmWrist,
        .forearmArm,
    ]

    private static let containerName = "HandTrackingEntitiesContainer"

    var rootEntity: Entity!

    func setup(entity: Entity) {
        rootEntity = entity

        let entity = ImmersiveViewModel.makeHandTrackingEntitiesAxis()
        rootEntity.addChild(entity)
    }

    func changeMode(mode: AppModel.Mode) {
        removeContainer()

        switch mode {
        case .axis:
            let entity = ImmersiveViewModel.makeHandTrackingEntitiesAxis()
            rootEntity.addChild(entity)
        case .bottle:
            let entity = ImmersiveViewModel.makeHandTrackingEntitiesBottle()
            rootEntity.addChild(entity)
        }
    }

    private func removeContainer() {
        for child in rootEntity.children {
            if child.name.hasPrefix(ImmersiveViewModel.containerName) {
                child.removeFromParent()
            }
        }
    }

    private static func makeHandTrackingEntitiesAxis() -> Entity {
        let container = Entity()
        container.name = ImmersiveViewModel.containerName + "Axis"

        let baseEntity = Entity.createAxes(axisScale: 0.02)

        for chirality in [AnchoringComponent.Target.Chirality.left, .right] {
            ImmersiveViewModel.handJoints.forEach { handJoint in
                let joint = AnchoringComponent.Target.HandLocation.joint(for: handJoint)
                let anchor = AnchorEntity(.hand(chirality, location: joint), trackingMode: .predicted)
                anchor.addChild(baseEntity.clone(recursive: true))
                container.addChild(anchor)
            }
        }

        return container
    }

    private static func makeHandTrackingEntitiesBottle() -> Entity {
        let container = Entity()
        container.name = ImmersiveViewModel.containerName + "Bottle"

        let modelEntity = try! Entity.loadModel(named: "teapot")
        modelEntity.scale *= 0.5

        let rotationQuaternionY = simd_quatf(angle: -.pi / 2, axis: SIMD3<Float>(0, 1, 0))
        let rotationQuaternionZ = simd_quatf(angle: .pi, axis: SIMD3<Float>(0, 0, 1))
        modelEntity.orientation *= (rotationQuaternionY * rotationQuaternionZ)

        modelEntity.position = [0.0, 0.18, 0.0]

        let anchor = AnchorEntity(.hand(.right, location: .palm), trackingMode: .predicted)
        anchor.addChild(modelEntity)
        container.addChild(anchor)

        return container
    }
}

extension Entity {

    static func createAxes(axisScale: Float, alpha: CGFloat = 1.0) -> Entity {
        let axisEntity = Entity()
        let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])

        let xAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1).withAlphaComponent(alpha))])
        let yAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1).withAlphaComponent(alpha))])
        let zAxis = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1).withAlphaComponent(alpha))])
        axisEntity.children.append(contentsOf: [xAxis, yAxis, zAxis])

        let axisMinorScale = axisScale / 20
        let axisAxisOffset = axisScale / 2.0 + axisMinorScale / 2.0

        xAxis.position = [axisAxisOffset, 0, 0]
        xAxis.scale = [axisScale, axisMinorScale, axisMinorScale]
        yAxis.position = [0, axisAxisOffset, 0]
        yAxis.scale = [axisMinorScale, axisScale, axisMinorScale]
        zAxis.position = [0, 0, axisAxisOffset]
        zAxis.scale = [axisMinorScale, axisMinorScale, axisScale]
        return axisEntity
    }
}
